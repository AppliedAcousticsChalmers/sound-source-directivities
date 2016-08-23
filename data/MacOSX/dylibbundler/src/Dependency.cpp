/*
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along
 with this program; if not, write to the Free Software Foundation, Inc.,
 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include "Dependency.h"
#include <iostream>
#include <cstdlib>
#include <sys/param.h>
#include "Utils.h"
#include "Settings.h"

#include <stdlib.h>
#include <sstream>
#include <vector>

std::string stripPrefix(std::string in)
{
    return in.substr(in.rfind("/")+1);
}

//the pathes to search for dylibs, store it globally to parse the environment variables only once
std::vector<std::string> pathes;

//initialize the dylib search pathes
void initSearchPathes(){
    //Check the same pathes the system would search for dylibs
    std::string searchPathes;
    char *dyldLibPath = std::getenv("DYLD_LIBRARY_PATH");
    if( dyldLibPath!=0 )
        searchPathes = dyldLibPath;
    dyldLibPath = std::getenv("DYLD_FALLBACK_FRAMEWORK_PATH");
    if (dyldLibPath != 0)
    {
        if (!searchPathes.empty() && searchPathes[ searchPathes.size()-1 ] != ':') searchPathes += ":"; 
        searchPathes += dyldLibPath;
    }
    dyldLibPath = std::getenv("DYLD_FALLBACK_LIBRARY_PATH");
    if (dyldLibPath!=0 )
    {
        if (!searchPathes.empty() && searchPathes[ searchPathes.size()-1 ] != ':') searchPathes += ":"; 
        searchPathes += dyldLibPath;
    }
    if (!searchPathes.empty())
    {
        std::stringstream ss(searchPathes);
        std::string item;
        while(std::getline(ss, item, ':'))
        {
            if (item[ item.size()-1 ] != '/') item += "/";
            pathes.push_back(item);
        }
    }
}

// if some libs are missing prefixes, this will be set to true
// more stuff will then be necessary to do
bool missing_prefixes = false;

Dependency::Dependency(std::string path)
{
    // check if given path is a symlink
    std::string cmd = "readlink -n " + path;
    const bool is_symlink = system( (cmd+" > /dev/null").c_str())==0;
    if (is_symlink)
    {
        char original_file_buffer[PATH_MAX];
        std::string original_file;
        
        if (not realpath(path.c_str(), original_file_buffer))
        {
            std::cerr << "\n/!\\ WARNING : Cannot resolve symlink '" << path.c_str() << "'" << std::endl;
            original_file = path;
        }
        else
        {
            original_file = original_file_buffer;
        }
        //original_file = original_file.substr(0, original_file.find("\n") );
        
        filename = stripPrefix(original_file);
        prefix = path.substr(0, path.rfind("/")+1);
        addSymlink(path);
    }
    else
    {
        filename = stripPrefix(path);
        prefix = path.substr(0, path.rfind("/")+1);
    }
    
    //check if the lib is in a known location
    if( !prefix.empty() && prefix[ prefix.size()-1 ] != '/' ) prefix += "/";
    if( prefix.empty() || !fileExists( prefix+filename ) )
    {
        //the pathes contains at least /usr/lib so if it is empty we have not initilazed it
        if( pathes.empty() ) initSearchPathes();
        
        //check if file is contained in one of the pathes
        for( size_t i=0; i<pathes.size(); ++i)
        {
            if (fileExists( pathes[i]+filename ))
            {
                std::cout << "FOUND " << filename << " in " << pathes[i] << std::endl;
                prefix = pathes[i];
                missing_prefixes = true; //the prefix was missing
                break;
            }
        }
    }
    
    //If the location is still unknown, ask the user for search path, ignore @loader_paths
    if( ( prefix.empty() || !fileExists( prefix+filename ) ) && prefix.find("@loader_path")==std::string::npos )
    {
        std::cerr << "\n/!\\ WARNING : Library " << filename << " has an incomplete name (location unknown)" << std::endl;
        missing_prefixes = true;
        
        while (true)
        {
            std::cout << "Please specify now where this library can be found (or write 'quit' to abort): ";  fflush(stdout);
            
            char buffer[128];
            std::cin >> buffer;
            prefix = buffer;
            std::cout << std::endl;
            
            if(prefix.compare("quit")==0) exit(1);
            
            if( !prefix.empty() && prefix[ prefix.size()-1 ] != '/' ) prefix += "/";
            
            if( !fileExists( prefix+filename ) )
            {
                std::cerr << (prefix+filename) << " does not exist. Try again" << std::endl;
                continue;
            }
            else
            {
                pathes.push_back( prefix );
                std::cerr << (prefix+filename) << " was found. /!\\MANUALLY CHECK THE EXECUTABLE WITH 'otool -L', DYLIBBUNDLDER MAY NOT HANDLE CORRECTLY THIS UNSTANDARD/ILL-FORMED DEPENDENCY" << std::endl;
                break;
            }
        }
    }
    
    //new_name  = filename.substr(0, filename.find(".")) + ".dylib";
    new_name = filename;
}

void Dependency::print()
{
    std::cout << std::endl;
    std::cout << " * " << filename.c_str() << " from " << prefix.c_str() << std::endl;
    
    const int symamount = symlinks.size();
    for(int n=0; n<symamount; n++)
        std::cout << "     symlink --> " << symlinks[n].c_str() << std::endl;;
}

std::string Dependency::getInstallPath()
{
    return Settings::destFolder() + new_name;
}
std::string Dependency::getInnerPath()
{
    return Settings::inside_lib_path() + new_name;
}


void Dependency::addSymlink(std::string s){ symlinks.push_back(stripPrefix(s)); }

// comapres the given Dependency with this one. If both refer to the same file,
// it returns true and merges both entries into one.
bool Dependency::mergeIfSameAs(Dependency& dep2)
{
    if(dep2.getOriginalFileName().compare(filename) == 0)
    {
        const int samount = dep2.getSymlinkAmount();
        for(int n=0; n<samount; n++)
            addSymlink( dep2.getSymlink(n) ); // FIXME - there may be duplicate symlinks
        return true;
    }
    return false;
}

void Dependency::copyYourself()
{
    copyFile(getOriginalPath(), getInstallPath());
    
    // Fix the lib's inner name
    std::string command = std::string("install_name_tool -id ") + getInnerPath() + " " + getInstallPath();
    if( systemp( command ) != 0 )
    {
        std::cerr << "\n\nError : An error occured while trying to change identity of library " << getInstallPath() << std::endl;
        exit(1);
    }
}

void Dependency::fixFileThatDependsOnMe(std::string file_to_fix)
{
    // for main lib file
    std::string command = std::string("install_name_tool -change ") +
    getOriginalPath() + " " + getInnerPath() + " " + file_to_fix;
    
    if( systemp( command ) != 0 )
    {
        std::cerr << "\n\nError : An error occured while trying to fix depencies of " << file_to_fix << std::endl;
        exit(1);
    }
    
    // for symlinks
    const int symamount = symlinks.size();
    for(int n=0; n<symamount; n++)
    {
        std::string command = std::string("install_name_tool -change ") +
        prefix+symlinks[n] + " " + getInnerPath() + " " + file_to_fix;
        
        if( systemp( command ) != 0 )
        {
            std::cerr << "\n\nError : An error occured while trying to fix depencies of " << file_to_fix << std::endl;
            exit(1);
        }
    }
    
    
    // FIXME - hackish
    if(missing_prefixes)
    {
        // for main lib file
        std::string command = std::string("install_name_tool -change ") +
        filename + " " + getInnerPath() + " " + file_to_fix;
        
        if( systemp( command ) != 0 )
        {
            std::cerr << "\n\nError : An error occured while trying to fix depencies of " << file_to_fix << std::endl;
            exit(1);
        }
        
        // for symlinks
        const int symamount = symlinks.size();
        for(int n=0; n<symamount; n++)
        {
            std::string command = std::string("install_name_tool -change ") +
            symlinks[n] + " " + getInnerPath() + " " + file_to_fix;
            
            if( systemp( command ) != 0 )
            {
                std::cerr << "\n\nError : An error occured while trying to fix depencies of " << file_to_fix << std::endl;
                exit(1);
            }
        }//next
    }// end if(missing_prefixes)
}

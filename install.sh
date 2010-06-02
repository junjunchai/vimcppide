#!/bin/sh
Clean()
{
    echo "Uninstall vim setting..."
    rm -rf $HOME/.vimrc
    rm -rf $HOME/.gvimrc
    rm -rf $HOME/.vim
}

CleanALL()
{
    Clean
    echo "Uninstall zshrc and screenrc..."
    rm -rf $HOME/.screenrc
    rm -rf $HOME/.zshrc
}

Install()
{
    echo "Install vim setting..."
    cp -R ./.vimrc $HOME
    cp -R ./.gvimrc $HOME
    cp -R ./.vim $HOME
}

InstallAll()
{
    Install
    echo "Install zshrc and screenrc..."
    cp -R ./.screenrc $HOME
    cp -R ./.zshrc    $HOME
}

Usage()
{
    echo "------------------------------------------------------"
    echo "Usage: $0 install/clean/cleanall/installall           "
    echo "       install only install vim settings              "
    echo "       installall will also install screenrc and zshrc"
    echo "Depend:ctags,cscope                                   "
    echo "------------------------------------------------------"
}

if [ ! $# = 1 ] ; then
    Usage
    exit
fi

echo "Note: Depend ctags and cscope been installed"

if [ $1 = "install" ] ; then
    Install
elif [ $1 = "--help" ] ; then
    Usage
elif [ $1 = "clean" ] ; then
    Clean
elif [ $1 = "cleanall" ] ; then
    CleanALL
elif [ $1 = "installall" ]; then
    InstallAll
else
    Usage
fi

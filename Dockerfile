FROM ubuntu:20.04

RUN apt update
RUN DEBIAN_FRONTEND=noninteractive apt install -y git wget curl build-essential python3
RUN wget https://github.com/neovim/neovim/releases/download/v0.6.1/nvim.appimage -O nvim
RUN bash -c 'chmod +x nvim && ./nvim --appimage-extract && cp -r squashfs-root/* . && rm -rf squashfs-root nvim'
RUN useradd -m ubuntu -s /bin/bash
USER ubuntu
RUN mkdir -p ~/.config && bash -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
RUN bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash'
RUN nvm install v16
RUN bash -c 'yes "" | nvim --headless --noplugin +PlugInstall +qall'

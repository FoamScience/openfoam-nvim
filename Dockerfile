FROM ubuntu:20.04

# Install common deps
RUN apt update
RUN DEBIAN_FRONTEND=noninteractive apt install -y git wget curl build-essential python3

# Download NVIM and unpack
RUN wget https://github.com/neovim/neovim/releases/download/v0.6.1/nvim.appimage -O nvim
RUN bash -c 'chmod +x nvim && ./nvim --appimage-extract && cp -r squashfs-root/* . && rm -rf squashfs-root nvim'

# Create dedicated user
RUN useradd -m ubuntu -s /bin/bash
USER ubuntu
SHELL ["/bin/bash", "-c"]

# Install nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# Install node LTS (v16)
RUN export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install v16 

# Install vim-plug
RUN mkdir -p /home/ubuntu/.config/nvim && sh -c 'curl -fLo /home/ubuntu/.config/nvim/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# Copy NVIM configs over
COPY ./init.vim /home/ubuntu/.config/nvim/init.vim

# Install plugins
RUN yes "" | nvim --headless --noplugins  +PlugInstall +qall
RUN yes "" | nvim --headless +"silent TSInstall foam" +"LspInstall foam" +qall

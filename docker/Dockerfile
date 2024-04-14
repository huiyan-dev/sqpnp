FROM ubuntu:22.04

# add apt source and use utf-8
ADD plugins/apt/sources.list /etc/apt/
RUN apt-get update && apt-get install -y ca-certificates locales && apt-get install -y locales && \ 
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo '$TZ' >/etc/timezone

# use zsh for better develop
RUN apt-get update && apt-get install -y zsh curl git
RUN yes | tr '[:lower:]' '[:upper:]' | bash -c "sh -c $(curl -fsSL https://install.ohmyz.sh)"
WORKDIR /root/.oh-my-zsh/custom/plugins/
RUN git clone https://github.com/zsh-users/zsh-autosuggestions.git --branch=v0.7.0 --depth=1 --no-tags -q
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git --branch=0.8.0 --depth=1 --no-tags -q
COPY plugins/zsh/.zshrc /root/.zshrc

# dependencices
RUN apt-get update && apt-get install -y libeigen3-dev libopencv-dev cmake build-essential

# run init when enter container
WORKDIR /workspace
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["../entrypoint.sh"]

FROM ubuntu:20.04 AS ros1

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gnupg2 lsb-release software-properties-common \
    build-essential git cmake \
    python3-pip \
    libceres-dev libeigen3-dev \
    libpcl-dev \
    nlohmann-json3-dev \
    tmux \
    libusb-1.0-0-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros/ubuntu $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/ros1.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-noetic-desktop-full \
    python3-rosdep \
    python3-catkin-tools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN git clone https://github.com/Livox-SDK/Livox-SDK.git && \
    cd Livox-SDK && \
    rm -rf build && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j$(nproc) && \
    make install

WORKDIR /ws_livox

RUN mkdir -p src

WORKDIR /ws_livox/src

RUN git clone https://github.com/Livox-SDK/livox_ros_driver.git

WORKDIR /ws_livox

RUN source /opt/ros/noetic/setup.bash && \
    catkin_make

WORKDIR /mandeye_ws

COPY ./src/common ./src/common
COPY ./src/mandeye_to_rosbag1 ./src/mandeye_to_rosbag1

RUN source /opt/ros/noetic/setup.bash && \
    source /ws_livox/devel/setup.bash && \
    catkin_make
    
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID ros && \
    useradd -m -u $UID -g $GID -s /bin/bash ros

RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc && \
    echo "source /mandeye_ws/devel/setup.bash" >> ~/.bashrc

FROM ubuntu:22.04 AS ros2

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl gnupg2 lsb-release \
    build-essential cmake git \
    python3-pip \
    libpcl-dev libeigen3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu jammy main" \
    > /etc/apt/sources.list.d/ros2.list

RUN apt-get update && apt-get install -y ros-humble-desktop && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install -U colcon-common-extensions

RUN python3 -m pip install "rosbags==0.10.5"

WORKDIR /mandeye_ws

COPY ./src/common ./src/common

COPY ./src/mandeye_to_rosbag2 ./src/mandeye_to_rosbag2

ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID ros && \
    useradd -m -u $UID -g $GID -s /bin/bash ros
    
RUN source /opt/ros/humble/setup.bash && colcon build

CMD ["bash"]

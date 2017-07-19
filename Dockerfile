FROM centos

ENV container=docker

RUN mkdir /etc/yum.repos.d/bak && mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak/ 
ADD install.repo /etc/yum.repos.d/install.repo 

RUN yum makecache; yum clean all
#RUN yum -y install initscripts nfs-utils && yum clean all
RUN yum -y install nfs-utils && yum clean all

RUN mkdir -p /exports
VOLUME ["/exports"]
EXPOSE 111/udp 111/tcp 2049/tcp 2049/udp 892/tcp 892/udp 662/udp 662/tcp 32768/tcp 32768/udp

ADD start.sh /usr/local/bin/start.sh 
RUN chmod -v +x /usr/local/bin/start.sh

#ENTRYPOINT /usr/sbin/init
#CMD ["/usr/sbin/init && /usr/local/bin/start.sh"]
CMD ["/usr/sbin/init"]
CMD ["/usr/local/bin/start.sh"]

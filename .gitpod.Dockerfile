FROM gitpod/workspace-postgres
USER gitpod
RUN bash -c "chmod +x ~/.sdkman/bin/sdkman-init.sh && . ~/.sdkman/bin/sdkman-init.sh && sdk install java 17.0.7-amzn && sdk default java 17.0.7-amzn"
RUN bash -c "echo ~/.sdkman/bin/sdkman-init.sh >> ~/.zshrc"

FROM gitpod/workspace-postgres
USER gitpod
RUN ". ~/.sdkman/bin/sdkman-init.sh && sdk install java 17.0.7-amzn && sdk default java 17.0.7-amzn"
RUN "echo ~/.sdkman/bin/sdkman-init.sh >> ~/.zshrc"

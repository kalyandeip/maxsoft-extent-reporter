# ─── Stage 1: Build with Maven & JDK 11 ─────────────────────────────
FROM maven:3.8.5-openjdk-11-slim AS builder
WORKDIR /app
COPY pom.xml ./
# Download dependencies only
RUN mvn dependency:go-offline -B
COPY src ./src
# Build and skip tests
RUN mvn clean package -DskipTests -B

# ─── Stage 2: Runtime with Chrome & App ────────────────────────────
FROM openjdk:11-jre-slim
WORKDIR /app

# Install Chrome + Chromedriver
RUN apt-get update && \
    apt-get install -y wget unzip gnupg && \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install -y google-chrome-stable && \
    CHROME_DRIVER_VERSION=$(wget -qO- https://chromedriver.storage.googleapis.com/LATEST_RELEASE) && \
    wget -O /tmp/chromedriver.zip "https://chromedriver.storage.googleapis.com/${CHROME_DRIVER_VERSION}/chromedriver_linux64.zip" && \
    unzip /tmp/chromedriver.zip -d /usr/local/bin && chmod +x /usr/local/bin/chromedriver && \
    rm /tmp/chromedriver.zip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy built JAR
COPY --from=builder /app/target/*.jar app.jar

# Default run command
ENTRYPOINT ["java","-jar","app.jar"]

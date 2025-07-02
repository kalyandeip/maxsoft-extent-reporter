# ─── Stage 1: Build & Dependencies ─────────────────
FROM maven:3.8.5-openjdk-11-slim AS builder

WORKDIR /app

# Copy only POM to leverage Docker cache for dependencies
COPY pom.xml ./

# Pre-download dependencies
RUN mvn dependency:go-offline -B

# Copy project source & build
COPY src ./src
RUN mvn clean package -DskipTests -B

# ─── Stage 2: Runtime Image ───────────────────────
FROM openjdk:11-jre-slim

WORKDIR /app

# Install Chrome and ChromeDriver
RUN apt-get update && apt-get install -y wget unzip gnupg \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update && apt-get install -y google-chrome-stable \
    && CHROME_DRIVER=$(wget -qO- https://chromedriver.storage.googleapis.com/LATEST_RELEASE) \
    && wget -O /tmp/chromedriver.zip "https://chromedriver.storage.googleapis.com/$CHROME_DRIVER/chromedriver_linux64.zip" \
    && unzip /tmp/chromedriver.zip -d /usr/local/bin && chmod +x /usr/local/bin/chromedriver \
    && rm /tmp/chromedriver.zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the JAR built in builder
COPY --from=builder /app/target/*.jar app.jar

# Expose port if your tests or server need it
EXPOSE 8080

# Execute the JAR (adjust main class or args as needed)
ENTRYPOINT ["java","-jar","app.jar"]

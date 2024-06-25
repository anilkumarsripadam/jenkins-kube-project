# Stage 1: Build the JAR file using Maven
FROM maven:3.8.4-openjdk-17-slim AS build
WORKDIR /app
COPY . .
RUN mvn clean install

# Stage 2: Build the Docker image
FROM docker:20.10.7  # Use the Docker client image
WORKDIR /app
COPY --from=build /app/target/*.jar /app/

# Expose the application port
EXPOSE 8080

# Use a shell command to dynamically identify the JAR file and run it
CMD ["sh", "-c", "java -jar /app/*.jar"]

# Stage 1: Build the JAR file using Maven
FROM maven:3.8.4-openjdk-17-slim AS build
WORKDIR /app
COPY . .
RUN mvn clean install

# Stage 2: Run the application
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/target/*.jar /app/

# Expose the application port
EXPOSE 8080

# Use a shell command to dynamically identify the JAR file and run it
CMD ["sh", "-c", "java -jar /app/*.jar"]

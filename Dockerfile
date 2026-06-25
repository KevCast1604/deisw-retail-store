# Multi-stage Dockerfile to build and run the Spring Boot application using Java 26.

# Stage 1: Build stage
FROM eclipse-temurin:26-jdk AS build
WORKDIR /app

# Copy Maven Wrapper files and pom.xml
COPY .mvn/ .mvn
COPY mvnw pom.xml ./

# Give execution permission to the Maven wrapper
RUN chmod +x mvnw

# Resolve dependencies (caches dependency layer)
RUN ./mvnw dependency:go-offline -B

# Copy the source code
COPY src ./src

# Build the application jar file (skipping tests since they will run in Jenkins)
RUN ./mvnw clean package -DskipTests

# Stage 2: Runtime stage
FROM eclipse-temurin:26-jre
WORKDIR /app

# Copy the built jar file from the builder stage
COPY --from=build /app/target/*.jar app.jar

# Expose the default application port (8096)
EXPOSE 8096

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]

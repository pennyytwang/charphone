FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /build

COPY pom.xml ./
RUN mvn -B -q dependency:go-offline

COPY src ./src
RUN mvn -B -q package -DskipTests

FROM tomcat:10-jdk17

RUN rm -rf /usr/local/tomcat/webapps/*

COPY --from=build /build/target/ROOT.war /usr/local/tomcat/webapps/ROOT.war
COPY server.xml /usr/local/tomcat/conf/server.xml

ENV CATALINA_OPTS="-Dfile.encoding=UTF-8"

EXPOSE 8080

CMD ["catalina.sh", "run"]

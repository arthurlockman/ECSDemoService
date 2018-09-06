FROM microsoft/dotnet:2.1-sdk as build
WORKDIR /build

COPY . ./
RUN dotnet restore

RUN dotnet publish --output /out/ --configuration Release

FROM microsoft/dotnet:2.1-aspnetcore-runtime
WORKDIR /dotnetapp
COPY --from=build /out/ .
EXPOSE 80

ENTRYPOINT ["dotnet", "ECSDemoService.dll"]

# @plotdb/print

pdf printer based on puppeteer.


## Usage

Install:

    npm install --save @plotdb/print


`@plotdb/print` uses puppeteer to generate PDF from html or link. You can run `@plotdb/print` as a print server in Docker (called 'Cloud Mode') and request PDF via API calls, or run puppeteer directly in your server (called 'Local Mode').


## Usage: Local Mode

Since you won't need puppeteer in local server when calling @plotdb/print in cloud mode, puppeteer related modules are optional and listed in peer dependencies and can be installed via:

    npm install puppeteer@^23.11.1 easy-pdf-merge@^0.2.6 tmp@^0.2.1

Then, in your code:

    # Get a printer instance 
    printer.get!
      .then ->
        # Print some html
        printer.print {html: "my html to be printed ..."}
      .then (buf) ->
        # Print via link
        printer.print {link: "https://to-your-website..."}
      .then (buf) -> # return a Buffer object of the desired PDF


## Usage: Cloud Mode

You will have first setup api endpoint that can generate PDF for you. Check `setup API endpoint` section below.

Once you have prepared the api endpoint, in your code:

    my-printer = new printer {server: {key: "your-api-key", url: "api-endpoint"}}
    my-printer.init!
      .then ->
        my-printer.print {link: "https://to-your-website..."}
      .then ({stream}) -> 
        # return a Stream object of the desired PDF, you can then e.g.:
        stream.pipe response


### setup API endpoint

To run @plotdb/print in cloud mode, a simple server exposing an API endpoint `/pdf` is available as `server.js`, which can be used independently or used with docker.

Note Puppeteer requires certain libraries in order to run with node:20-slim, which is listed in docker/Dockerfile; however based on versions this may vary so you should modify it if necessary.

Additionally, it might have issues running puppeteer in docker under MacOS, yet it will work in places such as Cloud Run.

You can find a Dockerfile under `docker` folder, which can be built by:

    cd <repo-root>
    docker buildx build --platform=linux/amd64 -t <your-tag> docker


### Run a Local Server

You can run the prepared local server via:

    cd <repo-root>
    node dist/server.js

You probably will want to create your owner version of print server, in this case you can refe to src/server.ls or web/server.ls for a minimal example of creating a print server.


### Deploy in Google Cloud Run with Docker Image

To build and push directly to Google Artifact Repository for later user:

    docker buildx build --platform=linux/amd64 \
           -t [your-region]-docker.pkg.dev/[project-id]/[repo-name]/[image-name]:latest \
           --push docker

For example:
    docker buildx build --platform=linux/amd64 \
           -t asia-east1-docker.pkg.dev/my-project/puppeteer-pdf/puppeteer-pdf:latest \
           --push docker

To deploy (use above name as example), you will need first create a secret:

    # create: note, this only need to be run once.
    gcloud secrets create APIKEY --data-file=<(echo "your-secret-key")
    # update: when you need to update your key. note old key won't be deleted automatically
    gcloud secrets versions add APIKEY --data-file=<(echo "new-key")

    gcloud run deploy my-pdf-service \
      --image=asia-east1-docker.pkg.dev/my-project/puppeteer-pdf/puppeteer-pdf:latest \
      --platform=managed \
      --region=asia-east1 \
      --allow-unauthenticated \
      --memory=512Mi \
      --cpu=1 \
      --update-secrets=APIKEY=APIKEY:latest

Once deployed, you can test it with the dummy api endpoint `ping` which should respond with a simple `pong` string:

    curl https://<your-cloud-run-domain>/ping


And you can use the secret key you used and the url provided by google cloud run to prepare the configuration for `@plotdb/print`:

    my-printer = new print {server: {key: "your-secret-key", url: "path-to-cloud-run-api"}
    my-printer.init!then -> ... 


## License

MIT

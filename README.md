# Legalmation

## Overview

This project provides an API and simple UI for parsing the plaintiff and defendant in a legal document. The expected input is an XML file representing a legal PDF. Upon document upload, the user can retrieve the plaintiff and defendant from the API. Document names must be unique.

### Document format assumptions

It is assumed that the document will have a bold heading containing the word "court". It is expected that directly under the heading, in a left column, the plaintiff and defendant are specified in the form "<PLAINTIFF> plaintiff v <DEFENDANT> defendant". For other formats, this parser is not guaranteed to correctly extract the legal parties.

## Setup

It is assumed that Elixir, Erlang, PostgresQL, and Node.js are already installed. To spin up this project, follow the below steps.

1. Ensure postgres is running. For homebrew users, this can be done by running `brew services start postgresql`.
2. Ensure a postgres user exists with username `postgres` and password `postgres`. This can be done by running the following:
```
psql postgres
CREATE USER postgres WITH PASSWORD 'postgres';
ALTER USER postgres WITH SUPERUSER;
\q
```
3. Run `mix setup` to initialize the database and get all dependencies.
4. Run `mix phx.server`.
5. Visit `http://localhost:4000/documents` to interact with the UI.

## Using the UI

In the UI, a user can upload a document by selecting `Browse...`, and clicking `Upload`. If the document is not in XML format or if the document name has already been taken, an error will be displayed. After hitting an error, you can return to `http://localhost:4000/documents` to try a new document.

Upon upload, the table will be updated with the document ID, Filename, Plaintiff and Defendant.

## Using the API

If direct use of the API is preferred, the user can navigate to `http://localhost:4000/api/graphiql` and use the graphiQL interface can be used. For more information about using a graphiQL interface, see the [documentation](https://www.gatsbyjs.com/docs/how-to/querying-data/running-queries-with-graphiql/). If one prefers cURL commands, see section [uploading a document via curl](#uploading-a-document-via-curl)

### Uploading a document via cURL

To upload a document via API, the following cURL command can be used. The PATH_TO_DOC should be replaced appropriately.
```
curl -X POST \
-F query="mutation { uploadDocument(document: \"doc\"){id, filename, plaintiff, defendant} }" \
-F doc=@PATH_TO_DOC.xml \
localhost:4000/api/graphql
```

This approach can be applied to run other queries. Simply replace the line `mutation { uploadDocument(document: \"doc\") }` with the desired query or mutation. 

## API Documentation

A JSON form of the API documentation can be generated with `mix gen.api.json`. This will create a `.json` API document. Alternatively, inside the graphiQL interface (accessible at `http://localhost:4000/api/graphiql`) the right-hand side has a "Docs" panel where documentation can be explored interactively.
# pgai-pondhouse-content-recsys

Companion repo for Pondhouse Data blog about building a recommendation system with pgai and pgvector

## Preparation

To run the sample SQL code as part of the Pondhouse Data blog about building
a recommendation system, set up your Timescale database as follows:

```bash
docker pull timescale/timescaledb-ha:pg16
docker run -d --name timescaledb -p 5432:5432 -e POSTGRES_PASSWORD=<your-password> timescale/timescaledb-ha:pg16

export OPENAI_API_KEY="<your-api-key>"

PGOPTIONS="-c ai.openai_api_key=$OPENAI_API_KEY" psql -h localhost -U postgres # if running on your localhost
# PGOPTIONS="-c ai.openai_api_key=$OPENAI_API_KEY" psql -d "postgres://postgres:<password>@<host>:5432" # if running remotely
```

## Example: Building a recommendation system with pgai and pgvector

To run the example, see file `recommender-with-pgai-pgvectorscale.sql` in this repo.

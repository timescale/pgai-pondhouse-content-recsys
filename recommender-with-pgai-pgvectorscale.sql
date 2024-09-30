-- Create pgai and pgvectorscale extensions
CREATE EXTENSION IF NOT EXISTS ai CASCADE;
CREATE EXTENSION IF NOT EXISTS vectorscale CASCADE;

-- Create demo data
CREATE TABLE IF NOT EXISTS blog_articles (
   id SERIAL PRIMARY KEY,
   title TEXT NOT NULL,
   content TEXT NOT NULL,
   summary TEXT,
   tags TEXT[],
   embedding VECTOR(1536)
);

INSERT INTO blog_articles (title, content)
VALUES (
    'The Future of Artificial Intelligence',
    'Artificial Intelligence (AI) is rapidly transforming various aspects of our lives, from the way we interact with technology to the way industries operate. AI systems are becoming more sophisticated, with advancements in machine learning, natural language processing, and robotics. This article explores the potential future developments in AI, such as enhanced machine learning algorithms, the rise of autonomous systems, and the integration of AI into everyday applications. We also discuss the ethical considerations and societal impacts of these advancements, including job displacement, privacy concerns, and the need for responsible AI development.'
);

-- Second Demo Blog Article
INSERT INTO blog_articles (title, content)
VALUES (
    'Understanding Climate Change',
    'Climate change is one of the most critical challenges facing humanity today. It refers to long-term changes in temperature, precipitation patterns, and other aspects of the Earths climate system. This article provides a comprehensive overview of climate change, including its scientific basis, observed impacts, and projections for the future. We delve into the greenhouse effect, the role of human activities in exacerbating climate change, and the potential consequences for ecosystems and human societies. Additionally, we explore strategies for mitigating climate change, such as reducing greenhouse gas emissions, transitioning to renewable energy sources, and implementing sustainable practices.'
);

-- Third Demo Blog Article
INSERT INTO blog_articles (title, content)
VALUES (
    'Healthy Eating: Tips and Tricks',
    'Maintaining a healthy diet is crucial for overall well-being and longevity. This article offers a variety of practical tips and strategies for improving your eating habits. We cover topics such as the importance of balanced nutrition, understanding macronutrients and micronutrients, and the benefits of incorporating a diverse range of foods into your diet. The article also provides advice on meal planning, mindful eating, and making healthier choices when dining out. By following these tips, you can enhance your nutritional intake, support your physical health, and improve your quality of life.'
);

-- create summaries for blog content
UPDATE blog_articles
SET summary = openai_chat_complete
( 'gpt-4o'
, jsonb_build_array
  ( jsonb_build_object('role', 'system', 'content', 'Your task is to summarize blog posts. The tone should be neutral and informative.')
  , jsonb_build_object('role', 'user', 'content', 'Text to summarize: ' || content)
  )
)->'choices'->0->'message'->>'content'

-- Create embeddings from blog summaries
UPDATE blog_articles
SET embedding = openai_embed('text-embedding-ada-002', summary);

-- Create insert trigger to automatically generate embeddings on insert
CREATE OR REPLACE FUNCTION create_embedding()
RETURNS TRIGGER AS $$
BEGIN
  NEW.embedding = openai_embed('text-embedding-ada-002', NEW.content);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_embedding_trigger
BEFORE INSERT OR UPDATE ON blog_articles
FOR EACH ROW
EXECUTE FUNCTION create_embedding();

-- Create index to use StreamingDiskANN for vector search
CREATE INDEX blog_articles_embedding_idx ON blog_articles
USING diskann (embedding);

-- Create function for vector similarity search
CREATE OR REPLACE FUNCTION find_similar_articles(article_text TEXT, result_limit INT)
RETURNS TABLE(title TEXT, content TEXT, distance FLOAT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        blog_articles.title,
        blog_articles.content,
        (blog_articles.embedding <=> openai_embed('text-embedding-ada-002', article_text)) AS distance
    FROM blog_articles
    ORDER BY distance
    LIMIT result_limit;
END;
$$ LANGUAGE plpgsql;

-- Use this function to find similar texts (Texts similar to 'Artificial Intelligence directly from your database' in this example)
SELECT * FROM find_similar_articles('Artificial Intelligence directly from your database', 10);

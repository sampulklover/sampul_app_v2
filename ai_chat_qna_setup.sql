-- AI Chat Q&A Knowledge Base
-- Structured question/answer pairs that the AI can use as low-token context

CREATE TABLE IF NOT EXISTS public.ai_chat_qna (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  tags TEXT[] DEFAULT '{}'::text[],
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users(id)
);

-- Basic index for active Q&A
CREATE INDEX IF NOT EXISTS idx_ai_chat_qna_active
  ON public.ai_chat_qna(is_active);

-- Optional simple text search index on question/answer
CREATE INDEX IF NOT EXISTS idx_ai_chat_qna_search
  ON public.ai_chat_qna
  USING GIN (to_tsvector('simple', coalesce(question, '') || ' ' || coalesce(answer, '')));

-- Enable Row Level Security
ALTER TABLE public.ai_chat_qna ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for idempotency)
DROP POLICY IF EXISTS "Anyone can read active AI chat QnA" ON public.ai_chat_qna;
DROP POLICY IF EXISTS "Admins can manage AI chat QnA" ON public.ai_chat_qna;

-- Policy: Anyone can read active Q&A (for app usage)
CREATE POLICY "Anyone can read active AI chat QnA"
ON public.ai_chat_qna
FOR SELECT
USING (is_active = true);

-- Policy: Only admins can insert/update/delete Q&A
CREATE POLICY "Admins can manage AI chat QnA"
ON public.ai_chat_qna
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.roles
    WHERE roles.uuid = auth.uid()
    AND roles.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.roles
    WHERE roles.uuid = auth.uid()
    AND roles.role = 'admin'
  )
);

-- Timestamp trigger to keep updated_at/updated_by fresh
CREATE OR REPLACE FUNCTION update_ai_chat_qna_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  NEW.updated_by = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_ai_chat_qna_timestamp ON public.ai_chat_qna;

CREATE TRIGGER update_ai_chat_qna_timestamp
BEFORE UPDATE ON public.ai_chat_qna
FOR EACH ROW
EXECUTE FUNCTION update_ai_chat_qna_updated_at();


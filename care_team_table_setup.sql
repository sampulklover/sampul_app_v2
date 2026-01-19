-- Create care_team table for storing care team members/consultants
CREATE TABLE IF NOT EXISTS public.care_team (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  name text NOT NULL,
  bio text NOT NULL,
  booking_url text NOT NULL,
  image_url text,
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer DEFAULT 0,
  CONSTRAINT care_team_pkey PRIMARY KEY (id)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_care_team_active ON public.care_team(is_active);
CREATE INDEX IF NOT EXISTS idx_care_team_sort_order ON public.care_team(sort_order);

-- Enable Row Level Security (RLS)
ALTER TABLE public.care_team ENABLE ROW LEVEL SECURITY;

-- Policy: Allow anyone to read active care team members
CREATE POLICY "Anyone can view active care team members"
  ON public.care_team
  FOR SELECT
  USING (is_active = true);

-- Insert sample data (optional - remove if you want to add via admin panel)
INSERT INTO public.care_team (name, bio, booking_url, image_url, is_active, sort_order)
VALUES 
  (
    'Arham Mercian - Estate Planning Consultant',
    'Registered Shariah Advisor',
    'https://cal.com/sampul/sampul-estate-planning-consultant-by-arham-merican?layout=month_view',
    NULL,
    true,
    1
  )
ON CONFLICT DO NOTHING;

-- Add comment to table
COMMENT ON TABLE public.care_team IS 'Stores care team members/consultants who can be booked for appointments';
COMMENT ON COLUMN public.care_team.name IS 'Full name and title of the care team member';
COMMENT ON COLUMN public.care_team.bio IS 'Short biography or credentials';
COMMENT ON COLUMN public.care_team.booking_url IS 'External URL for booking appointments (e.g., Cal.com link)';
COMMENT ON COLUMN public.care_team.image_url IS 'URL or path to profile image';
COMMENT ON COLUMN public.care_team.is_active IS 'Whether this member is currently active and should be displayed';
COMMENT ON COLUMN public.care_team.sort_order IS 'Order in which members should be displayed (lower numbers first)';













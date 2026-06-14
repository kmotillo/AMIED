import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://ebzjvrtfdqlscltbnlib.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImViemp2cnRmZHFsc2NsdGJubGliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzOTc3MTksImV4cCI6MjA5Njk3MzcxOX0.WbEppGR1nbm0O8wfTd3nf--Th8yMrnuqzYPfB3RisaA'

export const supabase = createClient(supabaseUrl, supabaseKey)

// Check auth state
export async function checkSession() {
  const { data: { session } } = await supabase.auth.getSession();
  return session;
}

// Ensure user is admin (you can add role check if needed)
export async function requireAuth() {
  const session = await checkSession();
  if (!session) {
    window.location.href = '/index.html';
  }
}

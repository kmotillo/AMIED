import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://ebzjvrtfdqlscltbnlib.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImViemp2cnRmZHFsc2NsdGJubGliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzOTc3MTksImV4cCI6MjA5Njk3MzcxOX0.WbEppGR1nbm0O8wfTd3nf--Th8yMrnuqzYPfB3RisaA';

const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
  console.log('Fetching completed progress...');
  const { data: progressList, error } = await supabase
    .from('user_progress')
    .select('user_id, course_id, completed_at, courses(title)')
    .not('completed_at', 'is', null);

  if (error) {
    console.error('Error fetching progress', error);
    return;
  }

  console.log(`Found ${progressList.length} completed courses.`);

  for (const prog of progressList) {
    const courseTitle = prog.courses?.title;
    if (!courseTitle) continue;

    const badgeName = `Medalla: ${courseTitle}`;
    
    // Check if badge exists
    let { data: badge } = await supabase.from('badges').select('id').eq('name', badgeName).maybeSingle();
    
    if (!badge) {
      console.log(`Creating badge: ${badgeName}`);
      const res = await supabase.from('badges').insert({
        name: badgeName,
        description: `Completaste exitosamente el curso: ${courseTitle}`,
        points_required: 0
      }).select('id').single();
      badge = res.data;
    }

    if (badge && badge.id) {
      // Award badge
      console.log(`Awarding badge ${badgeName} to user ${prog.user_id}`);
      await supabase.from('user_badges').upsert({
        user_id: prog.user_id,
        badge_id: badge.id
      });
    }
  }

  console.log('Retroactive medals assignment complete.');
}

run();

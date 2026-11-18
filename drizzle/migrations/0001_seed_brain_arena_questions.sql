
create or replace function pg_temp.add_q(_kind text, _topic text, _diff text, _prompt text, _correct text, _d1 text, _d2 text, _d3 text, _expl text)
returns void language plpgsql as $$
declare opts text[];
begin
  select array_agg(o order by random()) into opts from (select distinct unnest(array[_correct, _d1, _d2, _d3]) o) s;
  insert into public.quiz_questions (kind, topic, difficulty, prompt, options, correct_index, explanation)
  values (_kind, _topic, _diff, _prompt, opts, array_position(opts, _correct) - 1, _expl);
end; $$;

create or replace function pg_temp.ri(lo int, hi int) returns int language sql as $$ select lo + floor(random() * (hi - lo + 1))::int $$;

create or replace function pg_temp.add_num(_topic text, _diff text, _prompt text, _ans int, _expl text)
returns void language plpgsql as $$
declare d2 int;
begin
  d2 := _ans - pg_temp.ri(1, 5);
  if d2 < 0 then d2 := _ans + pg_temp.ri(6, 10); end if;
  perform pg_temp.add_q('math', _topic, _diff, _prompt, _ans::text,
    (_ans + pg_temp.ri(1, 5))::text, d2::text, (_ans + pg_temp.ri(11, 15))::text, _expl);
end; $$;

do $$
declare
  d text; lo int; hi int; mlo int; mhi int; i int; a int; b int; c int; x int; p int; base int;
  fr int[][]; n int; dd int; m int;
begin
  perform setseed(0.42);
  foreach d in array array['easy', 'medium', 'hard'] loop
    lo := case d when 'easy' then 2 when 'medium' then 12 else 50 end;
    hi := case d when 'easy' then 20 when 'medium' then 99 else 999 end;
    mlo := case d when 'easy' then 2 when 'medium' then 6 else 12 end;
    mhi := case d when 'easy' then 10 when 'medium' then 15 else 40 end;
    for i in 1..5 loop
      a := pg_temp.ri(lo, hi); b := pg_temp.ri(lo, hi);
      perform pg_temp.add_num('addition', d, format('What is %s + %s?', a, b), a + b,
        format('%s + %s = %s. Add the ones first, then the tens, carrying when a column passes 9.', a, b, a + b));
      a := pg_temp.ri(lo, hi); b := pg_temp.ri(lo, hi);
      if b > a then c := a; a := b; b := c; end if;
      perform pg_temp.add_num('subtraction', d, format('What is %s − %s?', a, b), a - b,
        format('%s − %s = %s. Check by adding back: %s + %s = %s.', a, b, a - b, a - b, b, a));
      a := pg_temp.ri(mlo, mhi); b := pg_temp.ri(mlo, mhi);
      perform pg_temp.add_num('multiplication', d, format('What is %s × %s?', a, b), a * b,
        format('%s × %s = %s. Think of it as %s groups of %s.', a, b, a * b, a, b));
      b := pg_temp.ri(mlo, mhi); x := pg_temp.ri(mlo, mhi);
      perform pg_temp.add_num('division', d, format('What is %s ÷ %s?', b * x, b), x,
        format('%s ÷ %s = %s, because %s × %s = %s.', b * x, b, x, b, x, b * x));
      p := case d when 'easy' then (array[10, 50, 25])[pg_temp.ri(1, 3)]
                  when 'medium' then (array[5, 15, 20, 75])[pg_temp.ri(1, 4)]
                  else (array[12, 35, 45, 8, 65])[pg_temp.ri(1, 5)] end;
      base := (array[100, 200, 400, 500, 600, 800, 1000, 1200])[pg_temp.ri(1, 8)];
      perform pg_temp.add_num('percentages', d, format('What is %s%% of %s?', p, base), p * base / 100,
        format('%s%% of %s = %s ÷ 100 × %s = %s.', p, base, p, base, p * base / 100));
      n := case d when 'easy' then 1 when 'medium' then pg_temp.ri(2, 3) else pg_temp.ri(3, 7) end;
      dd := case d when 'easy' then pg_temp.ri(2, 4) when 'medium' then pg_temp.ri(4, 5) else pg_temp.ri(8, 12) end;
      m := pg_temp.ri(2, case when d = 'hard' then 15 else 10 end);
      perform pg_temp.add_num('fractions', d, format('What is %s/%s of %s?', n, dd, dd * m), n * m,
        format('Divide %s by %s to get %s, then multiply by %s: %s.', dd * m, dd, m, n, n * m));
      x := pg_temp.ri(1, case d when 'easy' then 10 when 'medium' then 15 else 25 end);
      a := pg_temp.ri(2, case when d = 'hard' then 12 else 9 end);
      b := pg_temp.ri(1, 30);
      if d = 'easy' then
        perform pg_temp.add_num('algebra', d, format('Solve for x: x + %s = %s', b, x + b), x,
          format('Subtract %s from both sides: x = %s − %s = %s.', b, x + b, b, x));
      elsif d = 'medium' then
        perform pg_temp.add_num('algebra', d, format('Solve for x: %sx + %s = %s', a, b, a * x + b), x,
          format('Subtract %s: %sx = %s. Divide by %s: x = %s.', b, a, a * x, a, x));
      else
        c := pg_temp.ri(1, a - 1);
        perform pg_temp.add_num('algebra', d, format('Solve for x: %sx − %sx + %s = %s', a, c, b, (a - c) * x + b), x,
          format('Combine like terms: %sx + %s = %s. Subtract %s: %sx = %s. Divide: x = %s.', a - c, b, (a - c) * x + b, b, a - c, (a - c) * x, x));
      end if;
    end loop;
  end loop;
end $$;

-- Fraction addition (fixed, simplest form)
select pg_temp.add_q('math', 'fractions', 'easy', 'What is 1/4 + 1/2? (simplest form)', '3/4', '2/6', '1/2', '2/4', 'Use a common denominator: 1/4 + 2/4 = 3/4. Adding tops and bottoms separately (2/6) is a common mistake.');
select pg_temp.add_q('math', 'fractions', 'easy', 'What is 1/3 + 1/3?', '2/3', '2/6', '1/3', '1/9', 'Same denominators: add the tops. 1/3 + 1/3 = 2/3.');
select pg_temp.add_q('math', 'fractions', 'medium', 'What is 2/3 + 1/2? (simplest form)', '7/6', '3/5', '5/6', '4/3', 'Common denominator 6: 4/6 + 3/6 = 7/6.');
select pg_temp.add_q('math', 'fractions', 'medium', 'What is 3/4 − 1/8?', '5/8', '2/4', '1/2', '3/8', 'Common denominator 8: 6/8 − 1/8 = 5/8.');
select pg_temp.add_q('math', 'fractions', 'hard', 'What is 5/6 + 3/4? (simplest form)', '19/12', '8/10', '4/5', '17/12', 'Common denominator 12: 10/12 + 9/12 = 19/12.');
select pg_temp.add_q('math', 'fractions', 'hard', 'What is 2/3 × 9/10? (simplest form)', '3/5', '18/30', '11/13', '2/5', 'Multiply tops and bottoms: 18/30, which simplifies to 3/5.');

-- Logic puzzles (first option is correct)
select pg_temp.add_q('logic', 'number-patterns', 'easy', 'What comes next? 2, 4, 6, 8, …', '10', '9', '12', '16', 'Each number increases by 2, so 8 + 2 = 10.');
select pg_temp.add_q('logic', 'number-patterns', 'easy', 'What comes next? 5, 10, 15, 20, …', '25', '30', '22', '40', 'The pattern adds 5 each time.');
select pg_temp.add_q('logic', 'number-patterns', 'easy', 'What comes next? 1, 3, 5, 7, …', '9', '8', '11', '10', 'These are odd numbers, increasing by 2.');
select pg_temp.add_q('logic', 'number-patterns', 'medium', 'What comes next? 1, 4, 9, 16, …', '25', '20', '24', '32', 'Square numbers: 1², 2², 3², 4², so next is 5² = 25.');
select pg_temp.add_q('logic', 'number-patterns', 'medium', 'What comes next? 3, 6, 12, 24, …', '48', '36', '30', '27', 'Each number doubles.');
select pg_temp.add_q('logic', 'number-patterns', 'medium', 'What comes next? 1, 1, 2, 3, 5, 8, …', '13', '11', '12', '16', 'Fibonacci: each number is the sum of the two before it (5 + 8 = 13).');
select pg_temp.add_q('logic', 'number-patterns', 'medium', 'What comes next? 100, 90, 81, 73, …', '66', '65', '64', '70', 'The gaps shrink by 1: −10, −9, −8, then −7. 73 − 7 = 66.');
select pg_temp.add_q('logic', 'number-patterns', 'hard', 'What comes next? 2, 6, 12, 20, 30, …', '42', '40', '36', '44', 'Gaps are 4, 6, 8, 10, so the next gap is 12: 30 + 12 = 42.');
select pg_temp.add_q('logic', 'number-patterns', 'hard', 'What comes next? 1, 8, 27, 64, …', '125', '100', '81', '128', 'Cube numbers: 1³, 2³, 3³, 4³, so 5³ = 125.');
select pg_temp.add_q('logic', 'number-patterns', 'hard', 'What comes next? 2, 3, 5, 7, 11, 13, …', '17', '15', '16', '19', 'These are prime numbers. After 13 the next prime is 17.');
select pg_temp.add_q('logic', 'number-patterns', 'hard', 'What comes next? 1, 2, 6, 24, 120, …', '720', '240', '600', '144', 'Multiply by the next whole number each time: ×2, ×3, ×4, ×5, then ×6 = 720.');
select pg_temp.add_q('logic', 'reasoning', 'easy', 'All cats are animals. Tom is a cat. Which must be true?', 'Tom is an animal', 'All animals are cats', 'Tom is a dog', 'Some cats are not animals', 'If every cat is an animal and Tom is a cat, Tom must be an animal. The reverse is not guaranteed.');
select pg_temp.add_q('logic', 'reasoning', 'easy', 'If today is Monday, what day will it be in 3 days?', 'Thursday', 'Wednesday', 'Friday', 'Sunday', 'Tuesday (1), Wednesday (2), Thursday (3).');
select pg_temp.add_q('logic', 'reasoning', 'medium', 'Amy is taller than Ben. Ben is taller than Cara. Who is the shortest?', 'Cara', 'Ben', 'Amy', 'Can''t tell', 'Amy > Ben > Cara, so Cara is the shortest.');
select pg_temp.add_q('logic', 'reasoning', 'medium', 'Some students like chess. All chess lovers like puzzles. Which must be true?', 'Some students like puzzles', 'All students like puzzles', 'No students like puzzles', 'All puzzle lovers like chess', 'The students who like chess also like puzzles, so at least some students like puzzles.');
select pg_temp.add_q('logic', 'reasoning', 'medium', 'A clock shows 3:00. What is the angle between the hands?', '90°', '60°', '120°', '45°', 'Each hour mark is 30°. At 3:00 the hands are 3 marks apart: 3 × 30° = 90°.');
select pg_temp.add_q('logic', 'reasoning', 'hard', 'If it rains, the match is cancelled. The match was not cancelled. What can you conclude?', 'It did not rain', 'It rained', 'The match was postponed', 'Nothing at all', 'Contrapositive: if rain → cancelled, then not cancelled → no rain.');
select pg_temp.add_q('logic', 'reasoning', 'hard', 'Five people each shake hands once with everyone else. How many handshakes?', '10', '20', '25', '15', 'Each pair shakes once: 5 × 4 ÷ 2 = 10.');
select pg_temp.add_q('logic', 'brain-teasers', 'easy', 'How many months have 28 days?', 'All 12', '1', '2', 'None', 'Every month has at least 28 days.');
select pg_temp.add_q('logic', 'brain-teasers', 'easy', 'A farmer has 17 sheep. All but 9 run away. How many are left?', '9', '8', '17', '0', '“All but 9” means 9 stay.');
select pg_temp.add_q('logic', 'brain-teasers', 'medium', 'A bat and a ball cost 1.10 in total. The bat costs 1.00 more than the ball. How much is the ball?', '0.05', '0.10', '0.01', '0.15', 'If the ball is x, the bat is x + 1.00, so 2x + 1.00 = 1.10 and x = 0.05.');
select pg_temp.add_q('logic', 'brain-teasers', 'medium', 'You overtake the person in 2nd place in a race. What place are you in now?', '2nd', '1st', '3rd', 'Last', 'You take their position, so you are 2nd.');
select pg_temp.add_q('logic', 'brain-teasers', 'hard', 'If 5 machines make 5 widgets in 5 minutes, how long do 100 machines take to make 100 widgets?', '5 minutes', '100 minutes', '20 minutes', '1 minute', 'Each machine makes 1 widget in 5 minutes, so 100 machines make 100 widgets in the same 5 minutes.');
select pg_temp.add_q('logic', 'brain-teasers', 'hard', 'A lily pad patch doubles every day and covers a lake on day 48. When did it cover half the lake?', 'Day 47', 'Day 24', 'Day 46', 'Day 12', 'It doubles daily, so it was half the size one day before: day 47.');

-- Quick quiz (first option is correct)
select pg_temp.add_q('quiz', 'science', 'easy', 'What gas do plants absorb from the air for photosynthesis?', 'Carbon dioxide', 'Oxygen', 'Nitrogen', 'Helium', 'Plants take in carbon dioxide and release oxygen.');
select pg_temp.add_q('quiz', 'science', 'easy', 'At sea level, water boils at…', '100 °C', '90 °C', '50 °C', '120 °C', 'Water boils at 100 °C (212 °F) at standard sea-level pressure.');
select pg_temp.add_q('quiz', 'science', 'easy', 'Which planet is known as the Red Planet?', 'Mars', 'Venus', 'Jupiter', 'Mercury', 'Iron oxide (rust) on its surface makes Mars look red.');
select pg_temp.add_q('quiz', 'science', 'medium', 'Which part of a plant or animal cell holds most of its DNA?', 'Nucleus', 'Cell wall', 'Ribosome', 'Vacuole', 'DNA is mainly stored in the nucleus.');
select pg_temp.add_q('quiz', 'science', 'medium', 'What force keeps the Moon in orbit around Earth?', 'Gravity', 'Magnetism', 'Friction', 'Static electricity', 'Earth''s gravity bends the Moon''s path into an orbit.');
select pg_temp.add_q('quiz', 'science', 'medium', 'What is the chemical symbol for sodium?', 'Na', 'So', 'Sd', 'S', 'Na comes from sodium''s Latin name, natrium.');
select pg_temp.add_q('quiz', 'science', 'hard', 'Roughly how fast does light travel in a vacuum?', '300,000 km/s', '30,000 km/s', '3,000 km/s', '300 km/s', 'About 299,792 km per second.');
select pg_temp.add_q('quiz', 'science', 'hard', 'Which blood cells mainly fight infection?', 'White blood cells', 'Red blood cells', 'Platelets', 'Plasma', 'White blood cells are part of the immune system.');
select pg_temp.add_q('quiz', 'study', 'easy', 'Which technique reviews material over increasing gaps of time?', 'Spaced repetition', 'Cramming', 'Highlighting', 'Re-reading', 'Spaced repetition revisits material just as you are about to forget it.');
select pg_temp.add_q('quiz', 'study', 'medium', 'What is “active recall”?', 'Testing yourself from memory', 'Reading notes again', 'Copying the textbook', 'Studying with music', 'Pulling information out of memory builds stronger recall than re-reading.');
select pg_temp.add_q('quiz', 'study', 'medium', 'A classic Pomodoro focus block lasts about…', '25 minutes', '5 minutes', '2 hours', '60 seconds', 'Classic Pomodoro uses 25-minute focus blocks with short breaks.');
select pg_temp.add_q('quiz', 'technology', 'easy', 'What does “URL” stand for?', 'Uniform Resource Locator', 'Universal Read Link', 'User Resource List', 'Unified Routing Line', 'A URL is the address of a resource on the web.');
select pg_temp.add_q('quiz', 'technology', 'easy', 'Which is a strong password habit?', 'A unique password for each site', 'One password everywhere', 'Using your birthday', 'Sharing it with friends', 'Unique passwords stop one leak from exposing every account.');
select pg_temp.add_q('quiz', 'technology', 'medium', 'What does “CPU” stand for?', 'Central Processing Unit', 'Computer Power Unit', 'Core Program Utility', 'Central Peripheral Unit', 'The CPU executes program instructions.');
select pg_temp.add_q('quiz', 'technology', 'medium', 'How many bits are in a byte?', '8', '4', '16', '10', 'One byte is 8 bits.');
select pg_temp.add_q('quiz', 'technology', 'hard', 'What is “phishing”?', 'Tricking people into revealing information', 'A virus that deletes files', 'Speeding up a network', 'A programming language', 'Phishing uses fake messages or sites to steal passwords or data.');
select pg_temp.add_q('quiz', 'general', 'easy', 'How many continents are in the common seven-continent model?', '7', '5', '6', '8', 'Africa, Antarctica, Asia, Australia/Oceania, Europe, North America, South America.');
select pg_temp.add_q('quiz', 'general', 'easy', 'Which is the largest ocean?', 'Pacific', 'Atlantic', 'Indian', 'Arctic', 'The Pacific is the largest and deepest ocean.');
select pg_temp.add_q('quiz', 'general', 'medium', 'How many sides does a hexagon have?', '6', '5', '8', '7', '“Hex” means six.');
select pg_temp.add_q('quiz', 'general', 'medium', 'What is the longest bone in the human body?', 'Femur', 'Tibia', 'Humerus', 'Spine', 'The femur (thigh bone) is the longest.');
select pg_temp.add_q('quiz', 'general', 'hard', 'Which of these numbers is prime?', '29', '27', '21', '33', '29 has no divisors except 1 and itself. 27 = 3×9, 21 = 3×7, 33 = 3×11.');
select pg_temp.add_q('quiz', 'mathematics', 'easy', 'What is the perimeter of a square with 5 cm sides?', '20 cm', '25 cm', '10 cm', '15 cm', 'Perimeter = 4 × side = 20 cm.');
select pg_temp.add_q('quiz', 'mathematics', 'medium', 'What is the area of a triangle with base 10 and height 6?', '30', '60', '16', '36', 'Area = ½ × base × height = 30.');
select pg_temp.add_q('quiz', 'mathematics', 'medium', 'What is 0.25 as a fraction?', '1/4', '1/2', '2/5', '1/25', '0.25 = 25/100 = 1/4.');
select pg_temp.add_q('quiz', 'mathematics', 'hard', 'What is the sum of the interior angles of a pentagon?', '540°', '360°', '720°', '450°', '(n − 2) × 180° = 3 × 180° = 540°.');
select pg_temp.add_q('quiz', 'life', 'easy', 'Roughly how much sleep do most teenagers need each night?', '8–10 hours', '4–5 hours', '12–14 hours', '6 hours', 'Health guidelines suggest about 8–10 hours for teens.');
select pg_temp.add_q('quiz', 'life', 'medium', 'What is a budget?', 'A plan for spending and saving money', 'A type of bank account', 'A loan', 'A tax', 'A budget maps income to spending and saving.');
select pg_temp.add_q('quiz', 'creativity', 'easy', 'Which two paint colours mix to make green?', 'Blue and yellow', 'Red and blue', 'Red and yellow', 'Black and white', 'In paint mixing, blue + yellow = green.');
select pg_temp.add_q('quiz', 'creativity', 'medium', 'In 4/4 time, how many beats does a whole note last?', '4', '2', '1', '8', 'A whole note fills the full four beats of a 4/4 bar.');
select pg_temp.add_q('quiz', 'career', 'medium', 'What is the main purpose of a CV or résumé?', 'To summarise your skills and experience', 'To list hobbies only', 'To demand a salary', 'To replace an interview', 'A CV gives employers a quick summary of what you can do.');

-- Сравнив оба решения, вижу, что мой код получился довольно структурированным - каждый CTE
-- отвечает за свою задачу, что делает его легче читать и править при необходимости.
-- Правда, есть пара моментов, где я не совсем точно подошел к задаче. С навыками я использовал LAG 
-- и считал весь прогресс гнома, а в эталонном решении смотрят конкретно на то, как гном развился именно
-- в этом отряде - сравнивают уровень при поступлении с текущим. Согласен, это логичнее 
-- для оценки работы отряда."(Проблема молотка и гвоздей в действии. В прошлом задании изучил LAG и сразу
-- захотел его применить)" 
-- С тренировками тоже вышло не совсем корректно - связывал их с любыми битвами, не учитывая время. А надо было брать
-- только те сражения, что были после тренировок. Это дало бы более точную картину влияния 
-- подготовки на результаты.
-- В формуле эффективности я сделал упор на основные показатели, но можно было добавить больше нюансов.
-- В эталоне учитывают отступления, сколько лет отряд существует, когда начал и закончил воевать - это 
-- дает более полную картину. В итоге структурно мое решение неплохое, но детали
-- военного анализа проработал не до конца. Если бы совместить мой подход к организации кода с более
-- глубокой аналитикой из эталонного решения, вышло бы намного лучше.
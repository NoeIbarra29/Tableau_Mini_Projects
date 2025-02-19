USE covid_project;

-- Check if the data is complete after importating of both tables -- 
SELECT * FROM coviddeaths
ORDER BY location, date;

SELECT * FROM covidvaccinations
ORDER BY location, date;

-- Select the data to be used in the project --
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
ORDER BY location, date;

-- Compare total cases vs total deaths --
-- It shows the likelihood of dying if someone contracted covid in their country --
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_probability
FROM coviddeaths
ORDER BY location, date;

-- Look for total cases vs total deaths in Argentina --
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_probability
FROM coviddeaths
WHERE location = 'Argentina'
ORDER BY location, date;

-- Compare total cases vs population in Argentina -- 
-- It shows what percentage of the population contracted covid -- 
SELECT location, date, total_cases, population, (total_cases/population)*100 as cases_percentage
FROM coviddeaths
WHERE location = 'Argentina'
ORDER BY location, date;

-- Look for countries with the highest infection rate compared to population -- 
SELECT location, population, MAX(total_cases) as max_infection_count, MAX((total_cases/population))*100 as cases_percentage
FROM coviddeaths
GROUP BY location, population
ORDER BY cases_percentage desc;

-- Look for countries with the highest death rate --
SELECT location, population, MAX(total_deaths) as max_deaths_count
FROM coviddeaths
WHERE continent <> ''
GROUP BY location, population
ORDER BY max_deaths_count desc;

-- Breaking down the information by continent -- 
SELECT location, MAX(total_deaths) as total_deaths_count
FROM coviddeaths
WHERE continent = '' AND location NOT IN ('World', 'International', 'European Union')
GROUP BY location
ORDER BY total_deaths_count desc;

-- Look for global numbers -- 
SELECT sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, (sum(new_deaths)/sum(new_cases))*100 as global_death_percentage
FROM coviddeaths
WHERE continent <> '';

-- Global numbers by date -- 
SELECT date, sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, (sum(new_deaths)/sum(new_cases))*100 as global_death_percentage
FROM coviddeaths
WHERE continent <> ''
GROUP BY date
HAVING SUM(new_cases) is not null
ORDER BY date;

-- Look at total population vs total vaccinations --
-- It shows what percentage of the population was vaccinated --
-- Using CTE --  
WITH PopvsVac (continent, location, total_population, total_vaccinations)
AS
(
SELECT cd.continent, cd.location, MAX(cd.population) as total_population, sum(cv.new_vaccinations) as total_vaccinations
FROM coviddeaths as cd
JOIN covidvaccinations as cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent <> ''
GROUP BY cd.continent, cd.location
)
SELECT *, (total_vaccinations/total_population)*100 as vaccination_percentage FROM PopvsVac
ORDER BY total_population DESC;

-- Using a subquery as a temporary table -- 
SELECT continent, location, total_population, total_vaccinations, (total_vaccinations/total_population)*100 as vaccination_percentage 
FROM (
SELECT cd.continent, cd.location, MAX(cd.population) as total_population, sum(cv.new_vaccinations) as total_vaccinations
FROM coviddeaths as cd
JOIN covidvaccinations as cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent <> ''
GROUP BY cd.continent, cd.location
) AS PopvsVac
ORDER BY total_population DESC;

-- To see the evolution of the vaccination percentage over time in each country -- 
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
sum(cv.new_vaccinations) OVER (partition by cd.location order by cd.location, cd.date) as rolling_people_vaccinated
FROM coviddeaths as cd
JOIN covidvaccinations as cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent <> '' AND cd.population is not null AND cv.new_vaccinations is not null
)
SELECT *, (rolling_people_vaccinated/population)*100 as vaccination_percentage FROM PopvsVac;

-- Create a view with the evolution of vaccinations over time in each country -- 
CREATE VIEW population_vaccinated AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
sum(cv.new_vaccinations) OVER (partition by cd.location order by cd.location, cd.date) as rolling_people_vaccinated
FROM coviddeaths as cd
JOIN covidvaccinations as cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent <> '' AND cd.population is not null AND cv.new_vaccinations is not null;


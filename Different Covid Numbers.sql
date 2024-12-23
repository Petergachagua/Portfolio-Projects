SELECT *
  FROM [Portfolio Project1].[dbo].[CovidDeaths]
Order by 3, 4
 
SELECT * 
From [Portfolio Project1].[dbo].[CovidVaccinations]
order by 3, 4

-- below is the information used for querrying and data analysis

select location, date, total_cases as TC, new_cases as NC, total_deaths as TD
from [Portfolio Project1].[dbo].[CovidDeaths]
order by 1, 2

-- estimate the number of total cases versus that of total deaths in every country (mortality rates among infected persons)

select location, date, total_cases as TC, total_deaths as TD, (total_deaths/total_cases) * 100 as MortalityRates
from [Portfolio Project1].[dbo].[CovidDeaths]
where total_deaths is not NULL
order by 1, 2

-- identify the mortality rates in specific countries (Kenya and the Uited States)

select location, date, total_cases as TC, total_deaths as TD, (total_deaths/total_cases) * 100 as MortalityRates
from [Portfolio Project1].[dbo].[CovidDeaths]
where total_deaths is not NULL and (location = 'Kenya' or location like '%States')
order by MortalityRates

-- Identify the percentage of deaths relative to the population size in Kenya

select location, date, total_cases as TC, total_deaths as TD, population, (total_cases/Population) * 100 as InfectionRate
from [Portfolio Project1].[dbo].[CovidDeaths]
where total_cases is not NULL and location = 'Kenya'
order by InfectionRate

-- identifying the countries with the highest infection rates relative to the population size

SELECT location, MAX(total_cases) AS TC,population, MAX(total_cases * 1.0 / population) * 100 AS InfectionRate
FROM [Portfolio Project1].[dbo].[CovidDeaths]
GROUP BY location, population
ORDER BY InfectionRate desc 

-- This checks the country with the highest death counts per population

select location, max(total_deaths) as DeathCount
from [Portfolio Project1].[dbo].CovidDeaths
where total_deaths is not null and continent is not null
Group by location
order by DeathCount asc


-- Identify teh total Number of deaths in Kenya

select location, max(total_deaths) as DeathCount
from [Portfolio Project1].[dbo].CovidDeaths
where location= 'Kenya' and total_deaths is not null

-- showing the continents with the highest death counts

Select location, max(cast(Total_Deaths as int)) as TotalDeathCount
from [Portfolio Project1].[dbo].CovidDeaths
where continent is null and location <> 'World'
group by location
order by TotalDeathCount desc

select date, total_cases as TC, total_deaths as TD, (total_deaths/total_cases) * 100 as MortalityRates
from [Portfolio Project1].[dbo].[CovidDeaths]
where continent is not NULL
Group by date
order by 1, 2

Select sum(new_cases) as total_newcases, sum(cast(new_deaths as int)) as total_deaths, sum(cast (new_deaths as int))/sum(new_cases) *100 as DeathPercentage
From [Portfolio Project1].[dbo].[CovidDeaths]
Where continent is not null
Order by 1, 2

-- identify the total number of people in the world who were vaccinated

select * from [Portfolio Project1].[dbo].[CovidDeaths] cd
join [Portfolio Project1].[dbo].[CovidVaccinations] cv
on cd.location=cv.location
and cd.date=cv.date

-- identifying the number of vaccinations against the population sizes

select cd.continent, cd.date, cd.location, cd.population, cv.new_vaccinations, 
sum(cast(cv.new_vaccinations as int)) over (partition by cd.location order by cd.location, cd.date) as RollingSumofVaccinated
from [Portfolio Project1].[dbo].[CovidDeaths] cd
join [Portfolio Project1].[dbo].[CovidVaccinations] cv
on cd.location=cv.location
and cd.date=cv.date
where cd.continent is not null and cv.new_vaccinations is not null
order by 1, 2

-- Need to create a CTE

with PopulationVsVaccination (Continent, date, location, population, new_vaccinations, RollingSumofVaccinated)
as
(select cd.continent, cd.date, cd.location, cd.population, cv.new_vaccinations, 
sum(cast(cv.new_vaccinations as int)) over (partition by cd.location order by cd.location, cd.date) as RollingSumofVaccinated
from [Portfolio Project1].[dbo].[CovidDeaths] cd
join [Portfolio Project1].[dbo].[CovidVaccinations] cv
on cd.location=cv.location
and cd.date=cv.date
where cd.continent is not null and cv.new_vaccinations is not null)

select *,  (RollingSumofVaccinated/population) * 100 as PercentageofVaccinatedPopulation
from PopulationVsVaccination

order by Continent, date


-- Temporary Table

DROP TABLE IF EXISTS #PercentageofIndividualVaccinated;

CREATE TABLE #PercentageofIndividualVaccinated
(
    Continent NVARCHAR(255),
    location NVARCHAR(255),
    date DATETIME,
    Population NUMERIC,
    new_vaccinations NUMERIC,
    RollingSumofVaccinated NUMERIC
);

INSERT INTO #PercentageofIndividualVaccinated
SELECT 
    cd.continent, 
    cd.location, 
    CAST(cd.date AS DATETIME) AS date, 
    cd.population, 
    cv.new_vaccinations,
    SUM(CAST(ISNULL(cv.new_vaccinations, 0) AS INT)) 
    OVER (PARTITION BY cd.location ORDER BY cd.location, CAST(cd.date AS DATETIME)) AS RollingSumofVaccinated
FROM [Portfolio Project1].[dbo].[CovidDeaths] cd
JOIN [Portfolio Project1].[dbo].[CovidVaccinations] cv
ON cd.location = cv.location
AND CAST(cd.date AS DATETIME) = CAST(cv.date AS DATETIME);

SELECT *, (RollingSumofVaccinated / population) * 100 AS PercentageofVaccinatedPopulation
FROM #PercentageofIndividualVaccinated;

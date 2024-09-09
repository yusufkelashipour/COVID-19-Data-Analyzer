-- First, Replace Empty Cells with NULL, So that it can be Accessed Later

UPDATE CovidStatistics.coviddeaths
SET continent = NULL
WHERE continent = '';



-- Verify All Rows Were Imported Correctly
select count(*) from coviddeaths;
select count(*) from covidvaccine;


Select *
From CovidStatistics .coviddeaths
Where continent is not NULL;

Select *
From CovidStatistics .covidvaccine
order by 3,4;

-- Highlight Data that we are going to be analysing

Select Location, date, total_cases, new_cases, total_deaths, population
From CovidStatistics .coviddeaths;


-- Total Cases vs Total Deaths
-- Odds of dying when conflicted with covid
Select Location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 as DeathPercentage
From CovidStatistics .coviddeaths
Where location like '%Canada%';


-- Total Cases vs Population

Select Location, date, population ,total_cases , (total_cases / population) * 100 as InfectedPercentage
From CovidStatistics .coviddeaths
Where location like '%Canada%';



-- Finding Countries with Highest Infection Rate Compared to Population

Select Location, population, MAX(total_cases) as HighestInfectedCount, MAX((total_cases / population)) * 100 as HighestInfectedPercentage
From CovidStatistics .coviddeaths
Group by Location, population
order by HighestInfectedPercentage desc;


-- Total Death Count per Region

SELECT Location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM CovidStatistics.coviddeaths
Where continent is not NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Total Death Count per Continent
SELECT Continent, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM CovidStatistics.coviddeaths
Where continent is not NULL
GROUP BY Continent
ORDER BY TotalDeathCount DESC;

--  Global Statistics

Select SUM(new_cases) as Total_Cases, SUM(new_deaths) as Total_Deaths, SUM(new_deaths)/SUM(new_cases) * 100 as DeathPercent
From CovidStatistics .coviddeaths
Where continent is not NULL
-- Group by date
order by 1,2;

-- Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingVaccinations
From CovidStatistics .coviddeaths dea
Join CovidStatistics .covidvaccine vac
	On dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not NULL
order by 2,3;


With PopulationVsVaccination(continent, location, date, population, new_vaccinations, RollingVaccinations)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingVaccinations
From CovidStatistics .coviddeaths dea
Join CovidStatistics .covidvaccine vac
	On dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not NULL
-- order by 2,3
)

Select *, (RollingVaccinations/Population) *100
From PopulationVsVaccination;

-- Temp Table

-- Create the temporary table
DROP TEMPORARY TABLE IF EXISTS PercentofPopulationVaccinated;
CREATE TEMPORARY TABLE PercentofPopulationVaccinated
(
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATETIME,
    Population DECIMAL(18, 2),
    New_vaccinations DECIMAL(18, 2),
    RollingVaccinations DECIMAL(18, 2)
);

-- Insert data into the temporary table
INSERT INTO PercentofPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    COALESCE(NULLIF(vac.new_vaccinations, ''), 0) AS new_vaccinations,
    SUM(COALESCE(NULLIF(vac.new_vaccinations, ''), 0)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingVaccinations
FROM 
    CovidStatistics.coviddeaths dea
JOIN 
    CovidStatistics.covidvaccine vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;


-- Select data from the temporary table and calculate the percentage
SELECT 
    *, 
    (RollingVaccinations / Population) * 100 AS VaccinationPercentage
FROM 
    PercentofPopulationVaccinated;
    

-- Create View for Data Visualizations

Create View PercentofPeopleVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingVaccinations
From CovidStatistics .coviddeaths dea
Join CovidStatistics .covidvaccine vac
	On dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not NULL;
-- order by 2,3

Select *
From percentofpeoplevaccinated

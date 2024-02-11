/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Selecting data with non-null continents and ordering by continent and date
Select *
From CovidDeaths
Where continent is not null 
order by continent, date;

-- Selecting initial data for exploration, including location, date, total cases, new cases, total deaths, and population
Select Location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Where continent is not null 
order by Location, date;

-- Calculating the death percentage based on total cases for countries containing "states" in their name
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths
Where location like '%states%'
and continent is not null 
order by Location, date;

-- Calculating the percentage of population infected with Covid
Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths
order by Location, date;

-- Determining countries with the highest infection rate compared to population
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc;

-- Determining countries with the highest death count per population
Select Location, MAX(cast(Total_deaths as signed)) as TotalDeathCount
From CovidDeaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc;

-- Breaking down data by continent, showing continents with the highest death count per population
Select continent, MAX(cast(Total_deaths as signed)) as TotalDeathCount
From CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc;

-- Calculating global numbers including total cases, total deaths, and death percentage
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as signed)) as total_deaths, SUM(cast(new_deaths as signed))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
where continent is not null 
order by 1,2;

-- Determining the percentage of the population that has received at least one Covid vaccine
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT( vac.new_vaccinations, signed )) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
order by dea.location, dea.date;

-- Using CTE to perform calculation on partition by in previous query
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(vac.new_vaccinations, signed)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac;

-- Using Temp Table to perform calculation on partition by in previous query
-- Drop and create the temporary table
DROP TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TEMPORARY TABLE PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);


-- Insert data into the temporary table
INSERT INTO PercentPopulationVaccinated (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
SELECT
    dea.continent,
    dea.location,
    STR_TO_DATE(dea.date, '%d-%m-%Y'), -- Convert the date to the correct format
    dea.population,
    vac.new_vaccinations,
    (SELECT SUM(vac2.new_vaccinations)
     FROM CovidVaccinations vac2
     WHERE vac2.location = dea.location AND STR_TO_DATE(vac2.date, '%d-%m-%Y') <= STR_TO_DATE(dea.date, '%d-%m-%Y')
    ) AS RollingPeopleVaccinated
FROM
    CovidDeaths dea
JOIN
    CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date;



-- Query the data and calculate the percentage of rolling people vaccinated compared to the population
SELECT
    *,
    (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM
    PercentPopulationVaccinated ;


    



-- Creating View to store data for later visualizations
-- Drop the existing view if it exists
DROP VIEW IF EXISTS PercentPopulationVaccinated;

-- Create the new view
CREATE VIEW PercentPopulationVaccinated AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM
    CovidDeaths dea
JOIN
    CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL;




SELECT *
FROM ['cowid-covid-data(deaths)$']
WHERE Continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM ['cowid-covid-data(vaccination)$']
--ORDER BY 3,4

-- SELECT DATE THAT ARE WE ARE GOING TO BE USING

SELECT location, date,total_cases, new_cases, total_deaths, population
FROM ['cowid-covid-data(deaths)$']
ORDER BY 1,2

-- LOOKING AT TOTAL CASES VS TOTAL DEATHS

SELECT location, date, total_cases,  total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM ['cowid-covid-data(deaths)$']
WHERE location LIKE '%INDIA%'
ORDER BY 1,2

-- LOOKING AT THE TOTAL CASES VS POPULATION

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PopulationGotCovid
FROM ['cowid-covid-data(deaths)$']
WHERE location LIKE '%INDIA%'
ORDER BY 1,2


-- LOOKING AT THE COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO POPULATION
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PopulationGotCovid
FROM ['cowid-covid-data(deaths)$']
--WHERE location LIKE '%INDIA%'
GROUP BY location, population 
ORDER BY PopulationGotCovid desc

-- SHOWING THE COUNTRIES WITH THE HIGHEST DEATH COUNT PER POPULATION
SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM ['cowid-covid-data(deaths)$']
--WHERE location LIKE '%INDIA%'
WHERE  continent IS NULL
GROUP BY location 
ORDER BY TotalDeathCount desc

SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM ['cowid-covid-data(deaths)$']
--WHERE location LIKE '%INDIA%'
WHERE  continent IS	NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount desc

-- Showing the contient with the highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM ['cowid-covid-data(deaths)$']
--WHERE location LIKE '%INDIA%'
WHERE  continent IS	NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount desc

-- GLOBAL NUMBERS 
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100  AS DeathPercentage 
FROM ['cowid-covid-data(deaths)$'] 
--WHERE location LIKE '%INDIA%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2



-- LOOKING AT TOTAL POPULATION VS VACCINATIONS
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations, 
SUM(cast(VAC.new_vaccinations as bigint)) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS RollingPeopleVaccinated
FROM ['cowid-covid-data(deaths)$'] AS DEA
JOIN ['cowid-covid-data(vaccination)$'] AS VAC
 ON DEA.location = VAC.location
 AND DEA.date = VAC.date
 WHERE DEA.location LIKE '%INDIA%'
 --WHERE DEA.continent IS NOT NULL
 ORDER BY 2,3



 With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations
, SUM(CONVERT(bigint,VAC.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From ['cowid-covid-data(deaths)$'] AS DEA
Join ['cowid-covid-data(vaccination)$'] AS VAC
	On DEA.location = VAC.location
	and DEA.date = VAC.date
where DEA.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 AS RollingPeopleVaccinatedPercentage
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)


Insert into #PercentPopulationVaccinated
Select DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations
, SUM(CONVERT(bigint,VAC.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From ['cowid-covid-data(deaths)$'] AS DEA
Join ['cowid-covid-data(vaccination)$'] AS VAC
	On DEA.location = VAC.location
	and DEA.date = VAC.date
where DEA.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
Select DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations, 
SUM(CONVERT(bigint,VAC.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From ['cowid-covid-data(deaths)$'] AS DEA
Join ['cowid-covid-data(vaccination)$'] AS VAC
	On DEA.location = VAC.location
	and DEA.date = VAC.date
where DEA.continent is not null 
--order by 2,3

SELECT *
FROM PercentPopulationVaccinated
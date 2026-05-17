use portfolioproject;

ALTER TABLE covidvaccinations ALTER COLUMN median_age FLOAT;
ALTER TABLE covidvaccinations ALTER COLUMN gdp_per_capita FLOAT;
ALTER TABLE covidvaccinations ALTER COLUMN hospital_beds_per_thousand FLOAT;
ALTER TABLE covidvaccinations ALTER COLUMN life_expectancy FLOAT;

ALTER TABLE coviddeaths ALTER COLUMN total_cases FLOAT;
ALTER TABLE coviddeaths ALTER COLUMN new_cases_smoothed FLOAT;
ALTER TABLE coviddeaths ALTER COLUMN new_deaths_smoothed FLOAT;
ALTER TABLE coviddeaths ALTER COLUMN total_cases_per_million FLOAT;
ALTER TABLE coviddeaths ALTER COLUMN new_cases_per_million FLOAT;
ALTER TABLE coviddeaths ALTER COLUMN new_cases_smoothed_per_million FLOAT;
ALTER TABLE coviddeaths ALTER COLUMN total_deaths_per_million FLOAT;
ALTER TABLE coviddeaths ALTER COLUMN new_deaths_per_million FLOAT;
ALTER TABLE coviddeaths ALTER COLUMN new_deaths_smoothed_per_million FLOAT;

EXEC sp_help covidDeaths;

select * from coviddeaths;
select * from covidvaccinations;

select location, date, total_cases, new_cases, total_deaths, population from coviddeaths order by 1,2;

-- Looking at total death vs total cases 
select location, date, total_cases, total_deaths, cast(cast(total_deaths as decimal (18,2))/NULLIF(total_cases,0)*100 as decimal (10,2)) 
as Deathpercentage from coviddeaths where location like '%state%' order by 1,2;

-- Looking at total cases vs population 
select location, date, total_cases, cast(cast(total_cases as decimal (18,2))/NULLIF(Population,0)*100 as decimal (10,2)) 
as Deathpercentage from coviddeaths where location like '%state%'
order by 1,2;

select location, population, max(total_cases) HigestInfectionCount, cast(cast(max(total_cases) as decimal (18,2))/NULLIF(Population,0)*100 as decimal (10,2)) 
as PopulationInfected from coviddeaths group by location, population order by PopulationInfected desc;

--Sowing countries with higest death count per population
select location, max(cast(total_deaths as int)) as TotalDeathCount from coviddeaths where continent is not null
group by location order by TotalDeathCount desc; 

-- By continet
select continent, max(cast(total_deaths as int)) as TotalDeathCount from coviddeaths where continent is not null
group by continent order by TotalDeathCount desc;  

--Global Numbers
select date, cast(sum(new_cases) as int ) TotalCases, cast(sum(new_deaths) as int) as TotalDeaths, 
cast(cast(sum(new_cases) as int )/(sum(new_deaths))* 100 as int) as DeathParcentage
from coviddeaths where continent is not null group by date order by date;

-- covidvaccinstion
select * from covidvaccinations;

select distinct continent from covidvaccinations;

select dea.continent, dea.location , dea.date, dea.population, vac.new_vaccinations 
from coviddeaths dea join CovidVaccinations vac on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null order by 2,3;

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as RollingPopulationVaccinated
from coviddeaths dea join covidvaccinations vac
on dea.location = vac.location and dea.date = vac.date where dea.continent is not null order by 2,3;

-- USE CTE
with PopvsVac (continent, location, date, population, new_vaccinations, RollingPopulationVaccinated)
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as RollingPopulationVaccinated
from coviddeaths dea join covidvaccinations vac
on dea.location = vac.location and dea.date = vac.date where dea.continent is not null --order by 2,3
)
select*, (RollingPopulationVaccinated/population)*100 from PopvsVac

--TEMP TABLE

DROP table if exists Percentpupolationvacinated;

create table Percentpupolationvacinated
(
continent varchar(50),
location varchar(50),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPoplationVaccinated numeric
) 

insert into Percentpupolationvacinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as RollingPopulationVaccinated
from coviddeaths dea join covidvaccinations vac
on dea.location = vac.location and dea.date = vac.date --where dea.continent is not null --order by 2,3

select*, (RollingPopulationVaccinated/population)*100 from PopvsVac

--CREATING VIEW 

create view Percentpupolationvacinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as RollingPopulationVaccinated
from coviddeaths dea join covidvaccinations vac
on dea.location = vac.location and dea.date = vac.date --where dea.continent is not null --order by 2,3

select * from Percentpupolationvacinated;
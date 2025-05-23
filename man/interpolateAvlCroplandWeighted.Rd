% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/interpolateAvlCroplandWeighted.R
\name{interpolateAvlCroplandWeighted}
\alias{interpolateAvlCroplandWeighted}
\title{interpolateAvlCroplandWeighted}
\usage{
interpolateAvlCroplandWeighted(
  x,
  x_ini_lr,
  x_ini_hr,
  avl_cropland_hr,
  map,
  urban_land_hr = "static",
  marginal_land = "all_marginal",
  land_consv_hr = NULL,
  peat_hr = NULL,
  snv_pol_shr = 0,
  snv_pol_fader = NULL,
  year_ini = "y1985",
  unit = "Mha"
)
}
\arguments{
\item{x}{Time series of land pools (model output) to be disaggregated.}

\item{x_ini_lr}{The low resolution distribution of x before model optimization.}

\item{x_ini_hr}{The initial high resolution distribution of x (land-use initialisation) before model optimization.}

\item{avl_cropland_hr}{The area of available cropland at the high resolution.}

\item{map}{A relation map between low and high resolution, path or data.frame}

\item{urban_land_hr}{Either a magpie object of the cellular urban input data, or "static" string}

\item{marginal_land}{Depending on the cropland suitability data, standard options are
\itemize{
\item \code{"all_marginal"}: Cropland can be allocated to marginal land
\item \code{"q33_marginal"}: The bottom tertile of the marginal land area is excluded
\item \code{"no_marginal"}: Marginal land is fully excluded from cropland
}}

\item{land_consv_hr}{magpie object containing conservation land, e.g. \code{cell.conservation_land_0.5.mz} in the output folder}

\item{peat_hr}{Disaggregated peatland with MAgPIE peatland pools}

\item{snv_pol_shr}{Share of available cropland that is witheld for other land cover types. Can be supplied as a
single value or as a magpie object containing different values in each iso country.}

\item{snv_pol_fader}{Fader for share of set aside policy.}

\item{year_ini}{Timestep that is assumed for the initial distributions \code{x_ini_hr} and \code{x_ini_lr}.}

\item{unit}{Unit of the output. "Mha", "ha" or "share"}
}
\value{
The disaggregated MAgPIE object containing x_ini_hr as first
timestep
}
\description{
Disaggregates a modelled time series of land pools after optimisation from the model resolution (low resolution)
to the resolution of the land initialisation data set (high resolution), based on a relation map and available
cropland.
}
\details{
The function requires the following input data:
\itemize{
\item \code{x} is an object containing a time series of land pools (model output). The sum over all land pools
is constant over time.
\item \code{x_ini_lr} and \code{x_ini_hr} provide the initial land pools (Mha) at high (hr) and low resolution (lr)
before the optimisation. They only contain the initial time step, but share the three-dimensional structure
with \code{x}.
\item  \code{avl_cropland_hr} provides information about the amount (Mha) of available cropland at high resolution.
\item \code{map} relation map containing information about cell belongings between the high and low resolution.
}

The weighted disaggregation works as follows:

1. The share of cropland in terms of total available cropland is calculated at the previous time step and
then multiplied by the available cropland at the current time step (as available cropland can change over time
- e.g. by policy restriction as can be specified in \code{snv_pol_shr}). This temporary cropland pool is then
compared to the low resolution cropland pool and the residual area of cropland expansion and reduction is
determined.

2. In order to allocate residual area of cropland expansion and reduction, for each grid cell at high resolution
expansion and reduction weights are calculated and multiplied by the residual area:
\itemize{
\item The reduction weight is given by the ratio between the amount of cropland per grid cell and the total area
of the temporary cropland at the low resolution spatial unit. This assumes that the cropland reduction is equally
distributed among all high resolution grid cells.
\item The expansion weight is calculated as the ratio between the remaining cropland at the grid cell level
(high resolution) and the overall remaining cropland at the low resolution spatial unit in the current time step.
The remaining cropland given by the difference between the available cropland and the temporaryl cropland pool
minus urban land, since it assumed that cropland cannot be allocated to urban land.
}

3. Following the cropland allocation, the land area for the remaining non-cropland vegetation pools is calculated
by substracting the allocated cropland and urban land areas from the total land area in each grid cell.

4. The non-cropland vegetation pool at the high resolution (except of primary forest), calculated in step 3., is
then multiplied by the respective shares of the remaining non-cropland vegetation pools at the previous time step
(temporary allocation). Similar to the cropland allocation, is not sufficient to also account for changes within
these land pools. Therefore, the temporarily allocated non-cropland pools are, once again, compared with the pools
at low resolution. The residual area of land expansion and reduction is then allocated by based on reduction and
expansion weights, similar as in 2.. The reduction weight is calculated as the ratio between the given temporary
land pool at high resolution and total temporary land pool at low resolution. The expansion weight is calculated
as the ratio between the remaining land to be filled in each land pool and the total amount of residual land to
be allocated in the current time step.

5. Primary forest is treated in a slightly different way, as primary forest cannot be expanded over time. In
cropland cells with no cropland expansion, primary forest is, at first, assumed to remain constant and transferred
from the previous time step to the current time step. Once again, the sum of the temporarary allocation is compared
to the sum of primary forest at low resolution to determine the residual primary forest land, which still needs to
be allocated. Where there is an surplus of primary forest, the reduction weight is calculated similarly as in 5.,
the land area is reduced accordingly. In areas where the temprorily allocated primary forest falls short, the
allocation weight is calculated as a function of the difference in primary land between the previous time step and
in the current time step. This makes sure that there is no expansion of primary forest.

7. Urban land is assumed to be constant over time.
}
\examples{
\dontrun{
a <- interpolateAvlCroplandWeighted(
  x = land,
  x_ini_lr = land_ini_lr,
  x_ini_hr = land_ini_hr,
  avl_cropland_hr = "avl_cropland_0.5.mz",
  map = "clustermap_rev4.59_c200_h12.rds",
  marginal_land = "all_marginal"
)

sf <- read.magpie("f30_scenario_fader.csv")[, , "by2030"]

b <- interpolateAvlCroplandWeighted(
  x = land,
  x_ini_lr = land_ini_lr,
  x_ini_hr = land_ini_hr,
  avl_cropland_hr = "avl_cropland_0.5.mz",
  map = "clustermap_rev4.59_c200_h12.rds",
  marginal_land = "all_marginal",
  snv_pol_shr = 0.2,
  snv_pol_fader = sf
)

iso <- readGDX(gdx, "iso")
set_aside_iso <- readGDX(gdx, "policy_countries30")
set_aside_select <- readGDX(gdx, "s30_snv_shr")
set_aside_noselect <- readGDX(gdx, "s30_snv_shr_noselect")
snv_pol_shr <- new.magpie(iso, fill = snv_noselect)
snv_pol_shr[set_aside_iso, , ] <- set_aside_select

c <- interpolateAvlCroplandWeighted(
  x = land,
  x_ini_lr = land_ini_lr,
  x_ini_hr = land_ini_hr,
  avl_cropland_hr = "avl_cropland_0.5.mz",
  map = "clustermap_rev4.59_c200_h12.rds",
  marginal_land = "all_marginal",
  snv_pol_shr = snv_pol_shr,
  snv_pol_fader = saf
)
}

}
\seealso{
\code{\link{interpolate2}}
\code{\link[madrat]{toolAggregate}}
}
\author{
Patrick von Jeetze, David Chen
}

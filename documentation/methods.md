Methods
=======

**Lines of inquiry:**

-   **Transit:** Where are Philadelphians moving to and from through the
    City? Where and when are these flows emerging? How do today’s flow
    compare at baseline?
-   **Economy:** What are the emerging centers of economic opportunity
    over time and how do these clusters compare to baseline?
-   **Risk:** Where are Philadelphians crowding, relative to available
    space indoors and outdoors?

Data
----

The data that we will use in this study come from **SafeGraph**, a
provider of location data, which produces twin datasets—places and
patterns—that combine to track the flow of mobile phones between
residences and points of interest, like restaurants and bars. This study
will focus on Philadelphia and consider the role of location data in
aiding its opening as the impact of the novel coronavirus attenuates.
Because we want to consider policy in our analysis, the natural unit of
area of interest is the City of Philadelphia, which is contains roughly
23 thousand points of interest according to SafeGraph, including 5,100
restaurants—the most common category.

![](https://github.com/asrenninger/philamonitor/raw/master/viz/pois.png)

Should we want to expand our aperature to the larger region, Greater
Philadelphia spans 11 counties, broken into 4,300 block groups by the
Census Bureau. Taking this as our area of interest, there are 98,000
unique points of interest to examine, with predominant categories
including restaurants (16,100), doctors (4,800) or dentists (3,100).

Bias
----

SafeGraph have attempted to describe the
[bias](https://www.safegraph.com/blog/what-about-bias-in-the-safegraph-dataset)
of these data, finding that it is generally sampling a population
similar to that of the United States according to the Census Bureau. The
data come from a panel of 40 million devices, but these are not
distributed throughout nation in the same manner as the population:
Pennsylvanian devices constitute 3.9% of the 40 million tracked
population, but actual Pennsylvanians make up closer to 4% of the 322
million true population. Errors like this permeate all dimensions of the
data—demographic and geographic distributions alike. That said, the
correlation between devices and persons on measures of education and
income is 0.99, aided by the size of the dataset. SafeGraph appears to
have made a reasonable attempt create a dataset that maps well to
population as a whole. There may, of course, be spatial heterogeneities
in this bias—marked in some areas and trivial in others—and we can at
least estimate this in our work by comparing the ratio of devices to
people across the city.

![](https://github.com/asrenninger/philamonitor/raw/master/viz/devices.png)

Exploration
-----------

We can use this data to create matrices of interactions between
neighborhoods in Philadlephia, using matrix multiplication to view from
either the perspective of the neighborhood or the point of interest;
included in the patterns data are the origin block groups. Below we take
one area as an example. Near the Delaware River, this section of the
city has a Wal-Mart among several other popular chain stores. People
visit from across the city, though most people who live here stay here
during the day. We can use the `igraph` package to study the structure
of these networks along with the `sf` package to map them.

![](https://github.com/asrenninger/philamonitor/raw/master/viz/visits.png)

Further, also included in the patterns data is the number of visits by
hour or by day (though not by hour *and* by day), so we can build
spatio-temporal flows. These flows can be compared to a reference, as
SafeGraph provides data for 2019 and 2020. Rather than comparing to the
exact day in 2019, which would be noisy, we can instead construct
representative days of the week by season.

Identification
--------------

The more challenging task is to determine what constitutes a flow; as we
see in the map, many communities in Philadelphia send visitors to many
others, but this may not represent strong connection. Again to reduce
noise, we can aggregate by day, use week or weekend binaries, and again
track changes between seasons. We should, of course, also track changes
between mitigation techniques during the pandemic: when citizens are
ordered to shelter, their moves should be different than when they are
allowed to travel. [This
repository](https://github.com/COVID19StatePolicy/SocialDistancing),
compiled by academics at the University of Washington, follows progress
on this front.

Each definition of flow will depend on the use case: transit will likely
demand week-weekend and peak-nonpeak considerations, so that service may
vary. Economic development will explore variations by brand and
industry, to identify where experiences are diversifying, where they are
simplifying, and where specialist corridors are emerging. As above, we
can use matrix manipulations in the same way while filtering for time or
brand—or another consideration.

We can start by defining generally what a flow from one neighborhood to
another. We want to tune to signal over noise so each
neighborhood-neighborhood dyad will be aggregated by week for 2019 and
connect only neighborhoods that once or more per week for the entire
period. In other words, we can call a connection ephemeral if it only
appears occassionally throughout the year, but if it occurs at least
once per week, we can call it permanent. (This may change if we decide
that seasons are better units, rather than the whole year.) We can also
fit a model—likely using the `prophet` package—to construct a
counterfactual 2019 and then compare that to the factual 2020, a
techinque that is used population and migration studies; this will
smooth out variation. We would need to iterate through each dyad a fit a
curve to each.

For all inquiries we will develop a smoothed baseline on historic
conditions and compare the differences visually as a sanity check. Even
without a baseline, however, we can use a technique called **change
point** detection. [This
paper](https://www.jstatsoft.org/article/view/v058i03/v58i03.pdf)
explains in detail, but the approach generally fits a model that
attempts to minimize a cost (maximize fit) in the presence of a penalty
term for overfitting. One technique bifurcates the data until no change
points are detected, given the imperative above. The authors present a
package `changepoints` to implement three separate algorithms; we will
select one after testing each.

Change points can be discovered in flows between neighborhoods across
time, so the dataset that we will need to construct will include one row
per dyad per week or day in long form, with columns for dyad identifier
(likely “{tract id} to {tract id}”), date, and visits. For some
corridors, it might make sense to build a synthetic *area of interest*
by aggregating *points of interest*; we can use the `dbscan` package to
assign points of interest to clusters by proximity and density. In this
case, the dyad column will likely be “{home tract id} to {cluster id}”
and we can add a column to capture the industry mix of the cluster–is it
restaurants and bars or home goods?

Consolidation
-------------

Most of this time-space flow modelling will be devoted to transit
anaylsis. With a **many models** approach, we will need to find someway
to describe the phenomena visually in order to interpret it. We can
assign numbers to frequency and amplitude of change points and append
those attributes as weights in our graph. For economic development, we
can follow changing clusters—especially those that are shrinking—as well
as the flows between them. This will result in a series of maps and
graphs that illustrate the changing nature of mobility and business in
Philadelphia.

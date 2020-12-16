1 Introduction
--------------

As the coronavirus spread in Philadelphia this year, mobility patterns
changed. With this shock came fewer commutes to work; we changed where
we shopped, where we dined and how we traveled. In order to understand
the consequences of these changes, we use GPS data from mobile phones to
track travel patterns before and during the pandemic.

To do so, we collect data from [SafeGraph](https://www.safegraph.com/),
a provider of mobility data from iPhone and Android smartphones. Note
that SafeGraph gathers data on a [representative
sample](https://www.safegraph.com/blog/what-about-bias-in-the-safegraph-dataset)
(10%) of the population across the country, so our indicators are not
the true number of visits or journeys, but a sample. The data model is
explained in Figure 1.1. The number of **visitors** is the count of
devices arriving at a **point of interest (POI)** while a **connection**
is an origin-destination line between a Census Block Group and a point
of interest. A **flow** is also a connection, but with a **weight**
measuring the number of visitors traveling between origin and
destination.

### 1.1 Key definitions

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/infographic.gif)
Each visit is a mobile device entering into a point of interest; these
include parks and museums, restaurants and bars, or offices and
hospitals. In Figure 1.2 we map the distribution of these venues and
businesses for context. We classify each point of interest by its
description, which SafeGraph provides. [1] We can see that most
businesses cluster in Center City or nearby but no businesses cluster
more than restaurants and bars.

### 1.2 Distribution of points of interest

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/split_clean.png)
To demonstrate how connections form a mobility network throughout
Philadelphia, Figure 1.3 connects origins to destinations by month in
Philadelphia.

### 1.3 Connections over time

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/flows_clean.gif)

This analysis comprises different spatial scales: Citywide, Neighborhood
and Point of Interest. We can look *globally*, across the city, to
explore trends throughout; we can also think *locally*, dividing the
city up into cells or neighborhoods to probe variations within the city.
Finally, we can look at individual businesses or venues. Below, we
attempt to understand patterns at each scale in order to understand how
mobility has shifted since the onset of the pandemic.

2 How have visitations changed?
-------------------------------

In this section we explore trends in *visits*, defined as the count of
devices flowing to a point of interest or area, beginning with the city
as a whole. To see how the business environment is for chains across the
city, rather than any given location, we sum visits by brand. Figure 2.1
ranks chain retail stores by the number of visitors they received and
animates this change through the pandemic. Visits to dollar stores rise
gradually throughout the year; another important shift is away from
non-essential retail towards essential businesses like pharmacies.
Starbucks and Wawa occupy top spots for the first several weeks of the
year but when the shelter-in-place order occurs, visits fall and they
are replaced in the ranks by essentials like RiteAid and ShopRite.

### 2.1 Comparing foot traffic by brand

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/bars_clean.gif)

In Figure 2.2 we aggregate visits by industry, grouping by classes like
leisure (restaurants and bars) and tourism (museums and theaters). The
pandemic has curbed visits to each class of business, but hit
particularly is leisure and “other”, which includes offices. Tourism is
regaining visitors while shopping and grocers are not, perhaps as many
switch to digital commerce.

### 2.2 Industry trends by category

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/seriesxtype_clean.png)

Next, we look at how mobility varies across smaller geographic units to
determine whether or not the pandemic is impacting some parts of the
city more than others. We find large disparities between the best- and
worst- performing neighborhoods. Figure 2.3 explores trends across
[neighborhoods](https://github.com/azavea/geo-data/tree/master/Neighborhoods_Philadelphia);
neighborhoods dominated by office work, like the Navy Yard along with
Logan Square and Center City, saw precipitous declines in visits, but
neighborhoods with strong amenities and residential communities have
recovered. This suggests that economic activity may be shifting away
from Center City.

### 2.3 Neighborhood trends

<table>
<thead>
<tr class="header">
<th style="text-align: center;">Best</th>
<th style="text-align: center;">Worst</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: center;"><img src="https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/besthoods10.png" /></td>
<td style="text-align: center;"><img src="https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/worsthoods10.png" /></td>
</tr>
</tbody>
</table>

Figure 2.4 presents an alternative approach for visualizing neighborhood
visitations, plotting the rolling average of visits for each neighorhood
(in red) compared with the citywide mean trend (dotted lines). Many
neighborhoods in the Northeast and Northwest are rebounding while
University, Center and Old City are still down substantially.

### 2.4 Rolling averages

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/changexrolling_clean.png)

Because visits data are collected for each point of interest, it is
possible to explore these dynamics at smaller scales. Figure 2.5
aggregates visits to 500 meter squared grid cells and visualizes them
for each month between January and August. Visits fell in most cells
during the worst months of the pandemic, but the business district has
regained visitors each month.

### 2.5 Visits by month in gridded units

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/grid_clean.png)

Businesses are not evenly distributed across the city, however, so
understanding business activity requires a unit of analysis that
respects **commercial corridors**—zones where businesses cluster
together—of which the city has designated roughly 280. We look at visits
to restaurants and bars within commercial corridors below. The largest
corridors are Market West and Market East, on either side of City Hall
(boxed on the map), with 1712 and 1263 restaurants and bars
respectively, followed by Old City at 654 and another in University City
with 493: most of the business activity is concentrated in a few
locales.

### 2.6 Commercial corridors

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/corridors_clean.png)

Figure 2.6 maps percent change from January to August, while Figure 2.7
plots the trend in the top and bottom 10 of these corridors over time,
the greatest reduction in visitors is in Center City and at the Sports
Complex. Plazas like Oxford and Levick, home to a supermarket, and City
and Haverford see the smallest impact.

### 2.7 Corridor trends

<table>
<thead>
<tr class="header">
<th style="text-align: center;">Best</th>
<th style="text-align: center;">Worst</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: center;"><img src="https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/bestcorr10.png" /></td>
<td style="text-align: center;"><img src="https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/worstcorr10.png" /></td>
</tr>
</tbody>
</table>

3 How have connections change?
------------------------------

This section looks at **connections** to points of interest within the
network to see how these venues are driving changes. Figure 3.1
replicates the animation from Figure 1.3 as a series of images. Again,
the network changes dramatically as the pandemic sets in, but the
decline in connections is most marked in the center.

### 3.1 Connections by month

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/flows_clean.png)

Here we take a closer look at some key network connections in
Philadelphia. Figures 3.2 and 3.3 plot connections to the Comcast Center
and Reading Terminal Market, respectively. Economic activity in these
two key hubs declines dramatically during the worst months of the
pandemic.

### 3.2 Comcast Center in focus

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/comcast_clean.png)

While the Comcast Center represents office work, as a signal for
tourism, we can look at Reading Terminal Market; vendors on its premises
saw marked declines in visits beginning in April.

### 3.3 Reading Terminal in focus

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/market_clean.png)

These destinations are critical to Philadelphia’s office and tourist
economies, but what about the brands that serve thousands on a daily
basis? We can see the differential effect of the pandemic simply by
looking at the change in visits to Target stores and Planet Fitness
gyms. Both see similar numbers of visitors prior to the arrival of
coronavirus and they have a similar number of locations—12 Targets and
14 Planet Fitnesses. Connections to Target held steady throughout the
pandemic, even while—as we see above—many connections across the city
broke.

### 3.4 Connections to Target stores

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/target_clean.png)
We can compare this network and its progression through the pandemic to
Planet Fitness, which saw fewer connections across the city as case
rates grew.

### 3.5 Connections to Planet Fitness gyms

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/fitness_clean.png)

We can track changing connections for all brands in the city. Figure 3.6
shows the number of connections certain brands lost between January and
August selecting the top and bottom 10. It shows that brands deemed
essential businesses saw comparably less of a decline than others, along
with fast food restaurants. Some brands that did not see steep drops in
visitors are seeing visitors from fewer neighborhoods. The map shows the
locations of brands for context.

### 3.6 Relative brand connections

<table>
<thead>
<tr class="header">
<th style="text-align: center;">Rankings</th>
<th style="text-align: center;">Locations</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: center;"><img src="https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/connections.png" /></td>
<td style="text-align: center;"><img src="https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/businesses_clean.gif" width="1200"></td>
</tr>
</tbody>
</table>

4 Possible consequences
-----------------------

Might the pandemic further exacerbate Philadelphia’s deep socio-economic
divide? If communities of color and low-income communities are
disproportionately comprised of essential workers who cannot work from
home, then Census tracts with higher rates of non-white residents should
exhibit greater rates of outflows relative to communities with fewer
minorities. Figures 4.1 and 4.2 test this outflow proposition using
income and race, respectively.

### 4.1 Did trips change with income?

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/outxincome_clean.png)

In March, at the onset of the pandemic, more Philadelphians were leaving
their home tracts. In April, all communties see reductions in trips.
However, the higher the median income, the greater the reduction in
trips, though the correlation is weak. We plot the relationship between
race and mobility in Figure 4.2. There is no correlation here in any
month but March.

### 4.2 Did trips change with race?

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/outxblack_clean.png)

5 Conclusion
------------

The purpose of this report is to examine mobility patterns in
Philadelphia before and during the pandemic using cell phone mobility
data provided by SafeGraph. The visualizations built from these data
show large declines in mobility at the onset of the pandemic. While we
cannot access economic indicators for particular neighborhoods and
businesses throughout the City, as a proxy, these mobility data suggest
that many industries and corridors have experienced a tremendous loss in
economic activity in recent months.

The next stage of this work is to develop some interactive, web-based
visualizations that can help stakeholders in Philadelphia understand and
plan for a return to ‘normal’ mobility patterns.

[1] If that description contains “restaurant” or “bar”, we classify that
as leisure. Anything educational, from tutoring to public, private or
charter schools to tertiary education, we call that education. Tourism
includes museums and parks.

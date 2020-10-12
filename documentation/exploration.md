Exploration
===========

With the goal of understanding the time-space patterns of resident
movement in Philadelphia, the following section presents a series of
maps and tables. Note that SafeGraph captures a slice of the population,
attempting to monitor a representative sample of the population across
the country; that said, we can reduce noise through various aggregations
and by tracking trends, which are naturally indexed to population of
devices rather than the population as a whole. We definitions specified
in the following infographic: the number of visitors is the count of
devices flowing to a point of interest—be it from a given Census Block
Group or total—while a connection is an origin-destination line between
a Census Block Group and a point of interest, regardless of its weight.
We use both here to determine how many people are moving about the city
and from where to where, which calls to how integrated the city is
during the pandemic.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/infographic.gif)

Points of Interest
------------------

First, we can classify each point of interest by its description. If it
contains restuarant or bar, we call that leisure. Anything educational,
from tutoring to public, private or charter schools to tertiary
education, we call that education. Tourism includes museums and parks.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/split.png)

We can start by looking at which points of interest were most popular in
the beginning of the year and how that is changed in recent months. The
table below shows just that, alongside a map that generally conveys that
distribution locations across Philadelphia.

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
<td style="text-align: center;"><img src="https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/context.png" /></td>
</tr>
</tbody>
</table>

The airport fell in the ranks, though all others saw few visitors in
August than in January—even more striking when we consider weather,
which could have produced the opposite effect in other years. Malls and
shopping centers appear to have weathered the pandemic well, but the
shift to remote work should also appear in the data. We can look at
visits to the Comcast Center and the Plaza below it; visits in April and
May, as the coronavirus took hold in the city, fell to the point of
irrelevance.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/comcast.png)

Yet with offices vacant, parks should have swelled with visitors. We see
mixed evidence of this in the data. Philadelphia has four central
squares—Rittenhouse, Washington, Logan, and Franklin—which provide
important community amenity; all saw fewer visits in April and May than
later in the summer, suggesting winter patterns even as the weather
improved.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/market.png)

Aggregations
------------

Perhaps more valuable than probing individual points of interest is
aggregating by areal units. Philadelphia has roughly 150 neighborhoods
(we use
[definitions](https://github.com/azavea/geo-data/tree/master/Neighborhoods_Philadelphia)
from local firm Azavea) and each responded differently to the pandemic.
Neighborhoods dominated by office work, like the Navy Yard along with
Logan Square and Center City, saw precipitous declines in foot traffic,
but those with strong amenities and residential communities have
recovered. This suggests that demand for food, drink, and shopping may
be shifting away from the core. (Note: see the appendix for larger
tables.)

<table>
<thead>
<tr class="header">
<th style="text-align: center;">Best</th>
<th style="text-align: center;">Worst</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: center;"><img src="https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/top10.png" /></td>
<td style="text-align: center;"><img src="https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/bottom10.png" /></td>
</tr>
</tbody>
</table>

Using regular tesselations, we can aggregate to a grid of 500 meter
cells to see how this manifests across space. We are still aggregating
from points of interest, so this is visits to businesses, parks, museums
and the like, but by tile; this does not include visits to the
particular patch of land without setting foot in a point of interest.
The city hollowed out during the worst months of the pandemic but the
Old City, Center City, University City axis still appears to have
pockets of thriving activity in these maps.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/grid.png)

We can also aggregate by use, grouping by classes like leisure and
tourism. The pandemic had distinct effects on each class, but
particularly leisure—like restaurants and bars—and other; other includes
offices which also explains the steep fall. Interestingly, tourism is
recovery while shops and grocers are not, perhaps as many switch to
digital commerce.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/seriesxtype.png)

Below we define leisure as visits to restaurants and bars, and see that
there are distinct changes in the flow between March and April using a
technique called change point detection.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/changepoints.png)

From here, we can fit a similar model to each neighborhood based on the
food traffic to that region. We do this by aggregating visits to every
point of interest within a given boundary. This means that we are
measuring visits to points of interest, not general activity on the
streets and in the residences of a neighborhood. Rather than simply flag
the change points across time and space, we can instead pull from the
model the rate change at regular intervals throughout the period; these
changes, rates being the rates of visits, then show the volatility of
mobility patterns across time.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/changes.gif)

We can see that there is a period of abrupt change in April and May,
coinciding with the pandemic but starting later and ending earlier in
different neighborhoods. The appendix has a chart that logs each
significant change point (above 10 percent change in the trend
week-on-week) for each neighborhood, and maps the volatility associated
with them for additional clarity.

Appendix:
---------

<table>
<thead>
<tr class="header">
<th style="text-align: center;">Best</th>
<th style="text-align: center;">Worst</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: center;"><img src="https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/top20.png" /></td>
<td style="text-align: center;"><img src="https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/bottom20.png" /></td>
</tr>
</tbody>
</table>

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/volatility.png)

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/changexhoods.png)

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/changexmagnitude.png)

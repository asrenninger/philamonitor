Exploration
===========

As the coronavirus spread in Philadelphia this year, travel patterns
throughout the city changed. With this shock to human mobility came one
to business activity, as many areas saw reliable patrons forced to stay
home—especially during the shelter-in-place order which began in March
and continued into May. In order to understand the consequences of these
changes for business viability, we use mobile phone data to explore the
changing nature commercial demand in Philadelphia. This analysis will
focus primarily on night life—the restaurants and bars that both provide
jobs and support vibrant streets—but we also monitor certain bellwether
industries, like those with office work, that doubtless provide a
foundation for such night life.

With the goal of understanding the time-space patterns of resident
movement in Philadelphia, the following section presents data from
SafeGraph, a provider of such records. Note that SafeGraph monitors a
representative sample (30%) of the population across the country, so the
values shown below are not the true number of visits or journeys, but a
slice; that said, we can reduce noise through various aggregations and
by tracking trends, which are naturally indexed to population of devices
rather than the population as a whole. We use definitions specified in
the following infographic: the number of **visitors** is the count of
devices flowing to a point of interest—be it from a given Census Block
Group or total—while a **connection** is an origin-destination line
between a Census Block Group and a point of interest, regardless of its
weight. We use both here to determine how many people are moving about
the city and from where to where, which calls to how integrated the city
is during the pandemic. If one neighborhood is driving business along a
corridor or at a veneue, it may obscure the fact that diversity of
clientele—captured in the number of unique neighborhoods sending
visitors there—is falling.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/infographic.gif)

When we link each connection together, we create a network of
interactions, weighted by the size of the flow (the number of visits),
and in probing the changing structure of this network we can understand
the impact of the pandemic on urban life in Philadelphia.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/flows.gif)

This analysis comprises different scales, each elaborating on distinct
aspects of mobility and activity in Philadelphia. We can look
*globally*, across the city, to explore trends throughout; we can also
think *locally*, dividing the city up into cells or neighborhoods to
probe variations within the city. Finally, we can avoid aggregation,
looking at individual points or interest or grouping them
algorithmically. Below, we attempt to understand the data by engaging
them at each scale.

### Three Units of Analysis

1.  [Global, city](#global)
2.  [Local, neighborhood](#local)
3.  [Point of Interest](#poi)

global
------

In this section, we look at trends across the city, beginning with the
distribution of venues and businesses. We classify each point of
interest by its description, which SafeGraph provides. If that
description contains “restuarant” or “bar”, we call that leisure.
Anything educational, from tutoring to public, private or charter
schools to tertiary education, we call that education. Tourism includes
museums and parks. We can see that most businesses agglomerate in Center
City or nearby, suggesting that there is feedback loop, but no
businesses cluster more than restaurants and bars.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/split.png)
We also see how visitation is changing across time by tracking visits
across brands. The table below shows that brands associated with
necessities (Target and Walmart) are growing in popularily, along with
fast food restaurants, which one might expect in a time of constrained
budgets. The map explores pairs of like brands and their locations in
Philadelphia.

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
<td style="text-align: center;"><img src="https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/businesses.gif" width="1200"></td>
</tr>
</tbody>
</table>

The following animation supports this story. Dollar stores rise
gradually throughout the year, an expected change as residents both need
more home goods and need to save money; another important shift is away
from non-essential retail towards essential businesses like pharmacies.
Starbucks and Wawa occupy top spots for the first several weeks of the
year but when the shelter-in-place order sets in, patronage immediately
collapses and they are replaced in the ranks essential shops RiteAid and
ShopRite.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/bars.gif)

We also aggregate by use, grouping by classes like leisure and tourism.
The pandemic had distinct effects on each class, but particularly
leisure—like restaurants and bars—and other; other includes offices
which also explains the steep fall. Interestingly, tourism is recovering
while shops and grocers are not, perhaps as many switch to digital
commerce.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/seriesxtype.png)

local
-----

Perhaps more valuable than probing individual points of interest is
aggregating by areal units, which we do in this section. Philadelphia
has roughly 150 neighborhoods (we use
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
<td style="text-align: center;"><img src="https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/besthoods10.png" /></td>
<td style="text-align: center;"><img src="https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/worsthoods10.png" /></td>
</tr>
</tbody>
</table>

Using regular tesselations, we aggregate to a grid of 500 meter cells to
see how this manifests across space. We are still aggregating from
points of interest, so this is visits to businesses, parks, museums and
the like, but by tile; this does not include visits to the particular
patch of land without setting foot in a point of interest. The city
hollowed out during the worst months of the pandemic but the Old City,
Center City, University City axis still appears to have pockets of
thriving activity in these maps.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/grid.png)

Businesses cluster together and we can explore the strength of this
phenomenon by looking at commercial corridors in Philadelphia, of which
the city has designated roughly 280. Looking at night life, the largest
are Market West and Market East, on either side of city hall, with 1712
and 1263 restaurants and bars respectively, following by Old City at 654
and another in University City with 493: most of the business activity
is concentrated in a few locales.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/corridors.png)

When we plot trends in these clusters over time, it is clear that many
of the most successful areas are toward the periphery, perhaps dormitory
communities supported by remote work, and several of the least
successful are situated in the core. Notably among the worst performers
are the two Center City corridors, which depend on office work, and the
Sports Complex, which saw sports leagues take measures of protect
players and ban fans early on—and many of these restrictions are still
in place.

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

The relationship between centrality—distance to the Philadelphia’s
core—and activity is negligible: many corridors in or around Center City
did indeed see a decline, but so too did those that likely serve a local
clientelle.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/relationships.png)

poi
---

Finally, this section looks at individual points of interest, how they
perform over time and whether or not we can identify certain bellwether
businesses within the city. We start by looking at the network of
connections across the city. Drawing a line between each origin
(neighborhood) and destination (point of interest), there is a dense
web—a nearly saturated graph where all neighborhoods send visitors to
all other corners of the city. This web becomes sparser as the pandemic
came to the fore and there during the late summer there were fewer links
than during the late winter.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/flows.png)

As we saw above, the data show that big box stores like Target and
Walmart appear to have weathered the pandemic well, but the shift to
remote work should also appear in the data. We can look at visits to the
Comcast Center and the Plaza below it; visits in April and May, as the
coronavirus took hold in the city, fell substantially.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/comcast.png)

Yet with offices vacant, parks should have swelled with visitors. We see
mixed evidence of this in the data. Philadelphia has four central
squares—Rittenhouse, Washington, Logan, and Franklin—which provide
important community amenity; all saw fewer visits in April and May than
later in the summer, suggesting winter patterns continued even as the
weather improved. As a signal for tourism, we can look at Reading
Terminal Market; vendors between its walls saw marked declines in visits
beginning in April.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/market.png)

Anomaly Detection (WIP)
-----------------------

In order to understand trends in Philadelphia, we need to identify areas
that are rising or falling in popularity as mobility patterns change.
This requires a system for flagging significant changes and ignoring
insignificant ones, but we need to define significance. To start, we
test a method called changepoint detection, first on global trends, then
on local patterns.

Below we define leisure as visits to restaurants and bars, and see that
there are distinct changes in the flow between March and April using a
technique called change point detection. The model does not seem to
settle on change points in situations with little change; grocers saw
much less change than restaurants and the change points are far less
clear, appearing in pairs at each hinge.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/changepoints.png)

From here, we can fit a similar model to each neighborhood based on the
food traffic to that region. We do this by aggregating visits to every
point of interest within a given boundary. This means that we are
measuring visits to points of interest, not general activity on the
streets and in the residences of a neighborhood. Rather than simply show
the change points across time and space, we can instead show the rate
change at regular intervals throughout the period; these changes, rates
being the rates of visits, then show the volatility of mobility patterns
across time. Thus, the strength of change mapped below can be thought of
as an index of volatility.

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/tracker.gif)

We can see that there is a period of abrupt change in April and May,
coinciding with the pandemic but starting later and ending earlier in
different neighborhoods. The appendix has a chart that logs each
significant change point (above 10 percent change in the trend
week-on-week) for each neighborhood, and maps the volatility associated
with them for additional clarity.

Appendix
--------

<table>
<thead>
<tr class="header">
<th style="text-align: center;">Best</th>
<th style="text-align: center;">Worst</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: center;"><img src="https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/besthoods20.png" /></td>
<td style="text-align: center;"><img src="https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/worsthoods20.png" /></td>
</tr>
</tbody>
</table>

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/volatility.png)

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/changexhoods.png)

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/changexmagnitude.png)

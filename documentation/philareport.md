1 Introduction
--------------

As the coronavirus spread in Philadelphia this year, travel patterns
changed. With this shock to human mobility came another to business
activity, as far fewer of us traveled to work, amenities or other
pastimes. In order to understand the consequences of these changes, we
use mobile phone GPS data to explore how Philadelphians changed their
travel patterns before and during the pandemic. This analysis will
explore general trends before examining night life—the restaurants and
bars that both provide jobs and support vibrant streets—and certain
bellwether industries, like those with office work, that doubtless
provide a foundation for such night life.

With the goal of understanding the time-space patterns of resident
movement in Philadelphia, the following section presents data from
[SafeGraph](https://www.safegraph.com/), a provider of such records.
Note that SafeGraph collects data on a [representative
sample](https://www.safegraph.com/blog/what-about-bias-in-the-safegraph-dataset)
(10%) of the population across the country, so our indicators are not
the true number of visits or journeys, but a slice. The data contain the
terms defined in figure 1.1: the number of **visitors** is the count of
devices flowing to a point of interest—be it from a given Census Block
Group or total—while a **connection** is an origin-destination line
between a Census Block Group and a point of interest, regardless of its
weight. Our concern here is to track the flow of visitors from an origin
location to a destination location in order to map flows over time and
space.

### 1.1 Key definitions

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/infographic.gif)

Figure 1.2 below maps these origin-destination flows as network
connections to show the extent to which areas throughout Philadelphia
are connected to one another. Changes over time reveal how much the
network thins out as the pandemic grows.

### 1.2 Mobility network

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/flows.gif)

Each visit is a mobile device entering into a point of interest; these
include parks and museums, restaurants and bars, or offices and
hospitals. In figure 1.3 we map the distribution of these venues and
businesses for context. We classify each point of interest by its
description, which SafeGraph provides. [1] We can see that most
businesses cluster in Center City or nearby but no businesses cluster
more than restaurants and bars.

### 1.3 Business landscape

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/split.png)

This analysis comprises different spatial scales, Citywide, Neighborhood
and Point of Interest. We can look *globally*, across the city, to
explore trends throughout; we can also think *locally*, dividing the
city up into cells or neighborhoods to probe variations within the city.
Finally, we can look at individual businesses or venues. Below, we
attempt to understand patterns at each scale.

2 Citywide analysis
-------------------

In this section we explore trends and relationships manifest most
strongly at the global level, across the city. Best described by this
focus on the whole over its part are how certain brands and industries
are performing, regardless of location, and how certain variables
predict changes to activity and mobility in Philadelphia. We see how
visitation is changing across time by tracking visits across brands.
Figure 2.1 shows that brands associated with necessities (Target and
Walmart) saw comparably less of a decline than others, along with fast
food restaurants, which one might expect in a time of constrained
budgets. The map shows the locations of brands for context.

### 2.1 Brand performance

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

Figure 2.2, which ranks each brand by the number of visitors it received
and animates this change through the pandemic. Dollar stores rise
gradually throughout the year, an expected change as residents both need
more home goods and need to save money; another important shift is away
from non-essential retail towards essential businesses like pharmacies.
Starbucks and Wawa occupy top spots for the first several weeks of the
year but when the shelter-in-place order sets in, patronage immediately
collapses and they are replaced in the ranks by essential shops RiteAid
and ShopRite.

### 2.2 Changing fortunes

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/bars.gif)

In figure 2.1 we aggregate by use, grouping by classes like leisure
(restaurants and bars) and tourism (museums and theaters). The pandemic
had distinct effects on each class, but particularly leisure and other;
other includes offices which also explains the steep fall.
Interestingly, tourism is recovering while shops and grocers are not,
perhaps as many switch to digital commerce.

### 2.3 Industry trends

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/seriesxtype.png)

Changing mobility may influence or exacerbate existing problems in
Philadelphia, notably around equity and integration. Philadelphia still
shows patterns of concentrated poverty, segregated housing and isolated
pockets of prosperty; the pandemic could produce deeper disparities. One
risk is that communities of color and low income neighborhoods will not
be able to socially distance in the same capacity as affluent
communities. The data, however, do not give a clear signal. Below we
plot the relationship between outflows—individuals visiting points of
interest from a given tract—and key predictors: tract income and the
percentage of the tract that is African American. (Tracts allow for
better demographic estimates.) The story is clear for income, as during
the critical month of April few poor communities could afford to shelter
in place, but hazy for race.

### 2.4 Income and travel

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/outxincome.png)

The pandemic appears to have flattened an existing relationship between
race and mobility: in early days of the pandemic, communities of color
were more likely to receive visitors from the rest of the city, a
pattern that held for peak months of spread, but this relationship
weakens as more predominately white communities gained visitors in July
and August. When we plot the same travel patterns against income, we see
that wealthy communities are well below their baseline visits, perhaps
because many of the restaurant clusters are in relatively affluent
areas. While poor communities are more likely to have recovered to
baseline but some of the poorest areas are still lagging behind, more in
line with wealthy ones.

### 2.5 Race and travel

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/outxblack.png)

The story is similar when we look at inflows, which we document in the
appendix. This suggests that poor and minority areas have remained
comparable active during the pandemic, which may come with heightened
exposure alongside economic stability.

3 Neighborhood variation
------------------------

Perhaps more valuable than probing individual points of interest is
aggregating by areal units, which we do in this section. These allow us
to see how visits in particular are changing throughout the pandemic in
different parts of Philadelphia. Philadelphia has roughly 150
neighborhoods (we use
[definitions](https://github.com/azavea/geo-data/tree/master/Neighborhoods_Philadelphia)
from local firm Azavea) and each responded differently to the pandemic.
We explore trends across neighborhoods in figure 3.1; neighborhoods
dominated by office work, like the Navy Yard along with Logan Square and
Center City, saw precipitous declines in foot traffic, but those with
strong amenities and residential communities have recovered. This
suggests that demand for food, drink, and shopping may be shifting away
from the core. (Note: see the appendix for larger tables.)

### 3.1 Neighborhood trends

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

Using a regular grid, in figure 3.2, we aggregate to a grid of 500 meter
cells to see how this manifests across space. We are still aggregating
from points of interest, so this is visits to businesses, parks, museums
and the like, but by tile; this does not include visits to the
particular patch of land without setting foot in a point of interest.
The city hollowed out during the worst months of the pandemic but the
Old City, Center City, University City axis still appears to have
pockets of thriving activity in these maps.

### 3.2 Variation by time and geography

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/grid.png)

Businesses cluster together and we can explore the strength of this
phenomenon by looking at commercial corridors, of which the city has
designated roughly 280. Looking at night life in figure 3.3, the largest
are Market West and Market East, on either side of city hall, with 1712
and 1263 restaurants and bars respectively, following by Old City at 654
and another in University City with 493: most of the business activity
is concentrated in a few locales.

### 3.3 Commercial corridors

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/corridors.png)

When we plot trends in these clusters over time, it is clear that many
of the most successful areas are toward the periphery, perhaps dormitory
communities supported by remote work, and several of the least
successful are situated in the core. Notably among the worst performers
are the two central corridors, which depend on office work, and the
Sports Complex, which saw sports leagues take measures of protect
players and ban fans early on—and many of these restrictions are still
in place. Peripheral plazas like Oxford and Levick, home to a
supermarket, and City and Haverford are among the best.

### 3.4 Corridor trends

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

4 Points of Interest in focus
-----------------------------

This section looks at individual points of interest, how they perform
over time and whether or not we can identify certain bellwether
businesses within the city. These cases can provide further insight into
how the pandemic is changing mobility. We start by looking at the
network of connections across the city. Drawing a line between each
origin (neighborhood) and destination (point of interest), there is a
dense web—a nearly saturated graph where all neighborhoods send visitors
to all other corners of the city. This web becomes sparser as the
pandemic came to the fore and there during the late summer there were
fewer links than during the late winter.

### 4.1 Aggregate mobility

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/flows.png)

As we saw above, the data show that big box stores like Target and
Walmart appear to have weathered the pandemic well, but the shift to
remote work should also appear in the data. We can look at visits to the
Comcast Center and the Plaza below it; visits in April and May, as the
coronavirus took hold in the city, fell substantially.

### 4.2 Business in focus

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/comcast.png)

Yet with offices vacant, parks should have swelled with visitors. We see
mixed evidence of this in the data. Philadelphia has four central
squares—Rittenhouse, Washington, Logan, and Franklin—which provide
important community amenity; all saw fewer visits in April and May than
later in the summer, suggesting winter patterns continued even as the
weather improved. As a signal for tourism, we can look at Reading
Terminal Market; vendors between its walls saw marked declines in visits
beginning in April.

### 4.3 Tourism in focus

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/market.png)

5 Detecting trends
------------------

In order to understand trends we fit a rolling average to these
neighborhoods and plot these trends for context. The many neighborhoods
in the Northeast and Northwest are rebound while the axis of University,
Center and Old City are still down substantially.

### 5.1 Rolling averages

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/changexrolling.png)

Appendix
--------

### A.1 Expanding neighborhood ranks

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

### A.2 Explanatory variables

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/relationships.png)

### A.3 Expanding corridor ranks

<table>
<thead>
<tr class="header">
<th style="text-align: center;">Best</th>
<th style="text-align: center;">Worst</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: center;"><img src="https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/bestcorr20.png" /></td>
<td style="text-align: center;"><img src="https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/worstcorr20.png" /></td>
</tr>
</tbody>
</table>

### A.4 Visits by race and income

![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/inxblack.png)
![](https://raw.githubusercontent.com/asrenninger/philamonitor/master/viz/inxincome.png)

[1] If that description contains “restaurant” or “bar”, we classify that
as leisure. Anything educational, from tutoring to public, private or
charter schools to tertiary education, we call that education. Tourism
includes museums and parks.

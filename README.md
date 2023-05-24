# Places Case Study

## Coffee Places Feature Specs

### Story: User requests to see coffee places

### Narrative #1

```
As a user with an active internet connection
I want the app to load coffee places around me
So I can find a place to enjoy a cup of coffee.
```

#### Scenarios (Acceptance criteria)

```
Given the user has connectivity
 When the user requests coffee places
 Then the app should display coffee places nearby
  And replace the cache with the new places
```

### Narrative #2

```
As an offline user
I want the app to show the latest saved places
So at least I have some places I can browse through
```

#### Scenarios (Acceptance criteria)

```
Given the user doesn't have connectivity
  And there are places in the cache
  And the cache is less than one day old
 When the user requests to see places
 Then the app should display the saved places

Given the user doesn't have connectivity
 When the app displays the saved places
 Then the user should see an offline indicator 

Given the user doesn't have connectivity
  And there are places in the cache
  And the cache is one day old or more
 When the user requests to see places
 Then the app should display an error message

Given the user doesn't have connectivity
  And the cache is empty
 When the user requests to see places
 Then the app should display an error message
```

## Use Cases

### Get coffee places From Remote Use Case

#### Data:
- URL

#### Primary course (happy path):
1. Execute "Get Places" command with above data.
2. System downloads data from the URL.
3. System validates downloaded data.
4. System creates places from valid data.
5. System delivers places.

#### Invalid data – error course (sad path):
1. System delivers invalid data error.

#### No connectivity – error course (sad path):
1. System delivers connectivity error.

---

### Get coffee Places From Cache Use Case

#### Primary course:
1. Execute "Get Places" command with above data.
2. System retrieves feed data from cache.
3. System validates cache is less than one day old.
4. System creates places from cache.
5. System delivers places.

#### Retrieval error course (sad path):
1. System delivers error.

#### Expired cache course (sad path): 
1. System delivers no places.

#### Empty cache course (sad path): 
1. System delivers no places.

---

### Validate coffee places Cache Use Case

#### Primary course:
1. Execute "Validate Cache" command with above data.
2. System retrieves places from cache.
3. System validates cache is less than one day old.

#### Retrieval error course (sad path):
1. System deletes cache.

#### Expired cache course (sad path): 
1. System deletes cache.

---

### Cache Places Use Case

#### Data:
- Places

#### Primary course (happy path):
1. Execute "Save Places" command with above data.
2. System deletes old cache data.
3. System encodes places
4. System timestamps the new cache.
5. System saves new cache data.
6. System delivers success message.

#### Deleting error course (sad path):
1. System delivers error.

#### Saving error course (sad path):
1. System delivers error.

---

## Model Specs

### Place

| Property      | Type                |
|---------------|---------------------|
| `id`          | `UUID`              |
| `name`        | `String`            |
| `category`    | `String` (optional) |
| `location`    | `Location`          |
| `url`	        | `URL` (optional)    |



### Google Places Payload Example

```
GET /textsearch

200 RESPONSE

{
  "results":
    [
      {
        "formatted_address": "Some Address",
        "geometry":
          {
            "location": { "lat": -33.8592041, "lng": 151.2132635 },
          },
        "icon": "icon.png",
        "icon_background_color": "#FF9E67",
        "icon_mask_base_uri": "restaurant_pinlet",
        "name": "Restaurant Name",
        "opening_hours": { "open_now": false },
        "photos":
          [
            {
              "height": 4032,
              "html_attributions":
              "photo_reference": "XXX",
              "width": 3024,
            },
          ],
        "place_id": "XXX-Not_a_UUID",
        "price_level": 4,
        "rating": 4.5,
        "types": ["restaurant", "point_of_interest", "food", "establishment"],
        "user_ratings_total": 1681,
      },
      ....
    ]
}
```

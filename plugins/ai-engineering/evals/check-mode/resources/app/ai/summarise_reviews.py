import json

from openai import OpenAI

client = OpenAI()


def summarise_reviews(dish_name: str, reviews: list[str]) -> dict:
    prompt = (
        "You summarise restaurant reviews for the owner. Be concise. "
        f"Dish: {dish_name}. Reviews: " + " ".join(reviews) +
        " Return JSON with keys summary and sentiment."
    )
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
    )
    return json.loads(resp.choices[0].message.content)

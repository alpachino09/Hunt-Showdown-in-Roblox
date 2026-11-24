from .routes import render_road


def render_railway(route, parent, heights, terrain):
    render_road(route, parent, heights, terrain, railway=True)

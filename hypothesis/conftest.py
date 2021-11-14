import hypothesis

hypothesis.settings.register_profile(
    "search",
    max_examples=1000,
    phases=[
        hypothesis.Phase.generate,
        hypothesis.Phase.shrink,
    ],
)

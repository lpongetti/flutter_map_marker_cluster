can_publish:
	flutter upgrade --force && dart format --fix ./ && flutter analyze ./ && flutter test

publish:
	flutter upgrade --force && dart format --fix ./ && flutter analyze ./ && flutter test && flutter pub pub publish
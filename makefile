can_publish:
	flutter format --fix ./ && flutter analyze ./ && flutter test

publish:
	flutter format --fix ./ && flutter analyze ./ && flutter test && flutter pub pub publish
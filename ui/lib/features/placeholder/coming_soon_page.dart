import 'package:fluent_ui/fluent_ui.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({
    super.key,
    required this.title,
    required this.phase,
    this.description,
  });

  final String title;
  final String phase;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final resources = theme.resources;
    return ScaffoldPage(
      header: PageHeader(title: Text(title)),
      content: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FluentIcons.clock,
                size: 48,
                color: resources.textFillColorTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'Coming soon',
                style: theme.typography.subtitle?.copyWith(
                  color: resources.textFillColorSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                phase,
                style: theme.typography.caption?.copyWith(
                  color: resources.textFillColorTertiary,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 24),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: theme.typography.body?.copyWith(
                    color: resources.textFillColorSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

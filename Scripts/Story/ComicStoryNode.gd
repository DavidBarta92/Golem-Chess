extends StoryNode
class_name ComicStoryNode

## A run of full-screen comic pages.
##
## Each entry is a page scene (a ComicPage inherited scene under
## Story/Comic/) whose panel layout was arranged by hand in the editor. The
## order here is the order they are shown in; when the last panel of the last
## page has been revealed the node completes. Paths, not PackedScenes - see
## StoryNode.completion_scene_path; the player loads each page as it comes up.

@export_file("*.tscn") var page_paths: Array[String] = []

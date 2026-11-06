# improvement ideas

## Instance management

1. Show definitions and instances in one listing
2. Filter by definition, state, session, or workspace
3. Assign labels to instances
4. Show PID without exposing secret arguments
5. Start another instance from a definition
6. Restart a stopped instance with safe arguments
7. Pin frequently used instances
8. Hide definitions from quick-borrow list
9. Group definitions by category
10. Show home and current locations
11. Detect stale records
12. Export a definition as TOML
13. Import a definition from TOML
14. Validate executable before launch
15. Warn about port/lock conflicts
16. Set maximum instances per definition
17. Label instances by project
18. Show uptime
19. Show last borrow/return time
20. Provide read-only status for scripts

## Borrowing and tmux

21. Borrow beside active pane
22. Borrow into a new window
23. Choose target session/window
24. Borrow several selected utilities
25. Return active borrowed utility
26. Return utilities associated with host pane
27. Move host through manager and preserve association
28. Detect host closure
29. Offer orphan repair choices
30. Choose split direction
31. Set initial split percentage
32. Verify PID unchanged after move
33. Borrow complete managed window
34. Preview destination before move
35. Dry-run batch borrowing
36. Warn when destination is too small
37. Select target window with fzf
38. Borrow across sessions
39. Restore home placeholder
40. Detect external pane moves

tmuxake functionality is easy to add on top of tmu, we need to remember which pane last borrowed a utility and move it back and forth
	utility that once borrowed belonf to a pane and just that pane

## Layouts and workspaces

41. Save only managed panes
42. Restore into current window
43. Restore each utility in own window
44. Clone layout for another project
45. Reuse shared utilities during clone
46. Create per-window instances during clone
47. Prompt for project arguments
48. Save argument policy
49. Block secret values in layout
50. Name and describe layouts
51. Tag layouts by project type
52. Sort layouts by recent use
53. Preview layout contents
54. Validate all utilities before restore
55. Collect prompts before mutation
56. Rollback partial restore when safe
57. Save managed-pane arrangement
58. Store optional size proportions
59. Choose current or separate windows
60. Compare layout definitions

## Arguments and configuration

61. Prompt for required arguments
62. Use argv arrays
63. Support named presets
64. Mark presets portable
65. Support non-echoing secret prompts
66. Validate directory/file/integer arguments
67. Set optional argument defaults
68. Let CLI override definition defaults
69. Let layout preset override defaults
70. Use -- for executable argv
71. Ad-hoc launch supports manager options
72. Open config in editor
73. Append commented definition template
74. Provide readline wizard
75. Validate TOML before saving
76. Show effective merged config
77. Detect unknown config keys
78. Provide config migrations
79. Support per-utility environment
80. Redact secrets from diagnostics

## Lifecycle

81. Keep utilities running at home by default
82. Support utility-specific idle hooks
83. Run resume hook before borrow
84. Run idle hook after return
85. Allow declaration of unsafe suspension
86. Configure wait/shell/close on exit
87. Show exit status
88. Restart stopped instance
89. Capture hook status and diagnostics
90. Set hook timeout
91. Prevent concurrent hooks per instance
92. Refresh utility before borrow
93. Save utility state before stop
94. Record hook history
95. Confirm explicit stop
96. Graceful stop before force termination
97. Warn about unsaved work
98. Keep failed utility pane visible
99. Configure cleanup per utility
100. Provide lifecycle diagnostics


- directory specific utilities/env specific utilities can be used to filter the list of definitions and layouts


## UI and navigation

101. One compact popup entry point
102. fzf searchable selector
103. fzf multi-select only for batch-safe actions
104. Numbered selector without fzf
105. Show definition, ID suffix, and state
106. Show home/current location in preview
107. Configure popup dimensions
108. Keep tmux bindings minimal
109. Bash completion
110. Complete definition and layout names
111. Tree view of sessions/windows/instances
112. Copy instance ID
113. JSON output for scripts
114. Concise and verbose listings
115. Support non-interactive mode
116. Make cancellation side-effect free
117. Clear conflict messages
118. Open manager state directory
119. Help topic per command
120. Align popup actions with CLI

## Metadata and recovery

121. UUIDs for durable objects
122. Treat tmux IDs as runtime-only
123. SQLite transactions
124. Journal multi-step tmux operations
125. Reconcile before destructive actions
126. Foreign keys for relationships
127. Version database schema
128. Back up before migrations
129. Bounded SQLite busy timeout
130. Detect concurrent operations
131. Atomic config writes
132. Restrict state permissions
133. Never infer ownership from command line alone
134. Never kill unknown pane in cleanup
135. Doctor command
136. Explicit repair actions
137. Record partial operation results
138. Detect deleted home sessions
139. Recreate home placeholder
140. Export metadata for debugging

## Safety and security

141. Never persist secret args
142. Redact secret argv in logs
143. Validate hook executable paths
144. Avoid shell interpolation
145. Reject unsafe config types
146. Check symlink permissions
147. Warn on world-readable state directory
148. Use umask 077
149. Limit hook environment
150. Confirm destructive batch actions
151. Provide read-only audit mode
152. Record manager version in state
153. Avoid logging full environment
154. Validate working directories
155. Handle missing executables clearly
156. Avoid killing process groups blindly
157. Check PID reuse before signaling
158. Use process start time to verify PID
159. Require explicit force-stop
160. Provide safe uninstall

## Developer experience

161. Small independent command modules
162. Single tmux adapter
163. Single state access layer
164. Generate help from command metadata
165. Test isolated tmux server
166. Use ordinary panes as adversarial fixtures
167. Test PID preservation
168. Inject failures between tmux/database steps
169. Fake fzf for deterministic tests
170. Test prompts in pseudo-terminal
171. Check documentation links
172. Check table width automatically
173. Validate examples against CLI help
174. Dependency doctor
175. Reproducible release archive
176. Changelog
177. Document supported tmux versions
178. Document external-move limitations
179. Clean install/uninstall tests
180. Contribution guide

## Future extensions

181. Optional status-line summary
182. Optional notification on failed hook
183. Per-utility icon-free labels
184. Import/export layout bundle
185. Layout version history
186. Layout diff
187. Per-project config overlays
188. Read-only remote inventory
189. Plugin hook interface
190. Custom selector command
191. Alternative selector without fzf
192. Multiple tmux server support
193. Named environment profiles
194. Workspace detection from cwd
195. Project root discovery
196. Utility health checks
197. Utility readiness probes
198. Per-utility startup timeout
199. Per-utility shutdown timeout
200. Compatibility test matrix

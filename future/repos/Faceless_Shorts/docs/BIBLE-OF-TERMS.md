# Bible of Terms

## MASTER ARCHITECTURE

**Event-Driven Temporal Assembly Pipeline**
A deterministic, automated system that receives trigger events (user goals, scene changes, API calls) and assembles clips into a temporally coherent full video via predefined sequencing rules.

---

## VIDEO PRODUCTION / EDITING TERMINOLOGY

### Temporal Domain

**Temporal Interpolation:** Generating intermediate frames between existing frames to increase smoothness or frame rate.

**Temporal Coherence Synthesis:** Creating motion and appearance that remain consistent across time in a video sequence.

**Temporal Consistency Enforcement:** Applying constraints or multi-pass checks to prevent flickering, drifting objects, or lighting inconsistencies over time.

**Temporal Narrative Binding:** Locking visual events to story beats so the timeline supports narrative progression.

**Temporal Frame Repairs:** Blending or averaging adjacent frames to reduce artifacts or create stylistic motion blur.

**Temporal Anchor:** A fixed timecode or event marker that locks a clip's position on the timeline, preventing drift during assembly.

### Keyframe Operations

**Keyframe Interpolation:** Automatically calculating parameter values (position, scale, opacity, etc.) between two keyframes.

**Keyframe Blending:** Smoothly merging properties of adjacent keyframes for seamless transitions.

**Keyframe-Guided Video Synthesis:** Using user-provided keyframes as control points to direct AI video generation.

**Keyframe Retiming:** Adjusting the timing/duration between keyframes without altering the keyframes themselves.

**Keyframe Protocol:** Standardized method for defining, storing, and applying keyframe data across tools.

### Assembly/Stitching

**Deterministic Clip Assembly:** Rule-based, repeatable joining of clips with no randomness.

**Event-Driven Clip Assembly:** Trigger-based concatenation (e.g., new goal → add clip).

**Narrative Frame Stitching:** Seamlessly connecting shots to advance story logic.

**Shot Stitching:** Basic technical joining of two shots with matched action or eyeline.

**Segment Concatenation:** Simple end-to-end linking of video segments.

**Clip Concatenation:** Direct appending of clips (often with crossfades).

**Frame-Accurate Assembly:** Joining clips at exact frame boundaries for perfect sync.

**Timeline Compositing:** Layering and sequencing clips on a multi-track timeline.

**A/B Roll Assembly:** Alternating between two rolls/tracks for cuts or dissolves (classic editing technique).

### Editing Techniques

**J-Cut Temporal Offset:** Audio from the next scene begins before the picture cuts (J shape in timeline).

**L-Cut Audio Lead:** Picture cuts before the audio ends, letting previous scene audio spill over.

**NLE Sequencing:** Non-linear editing arrangement of clips on a digital timeline.

**EDL Assembly:** Using an Edit Decision List file to automatically assemble clips in supported software.

**Reaction-Synchronized Editing:** Cutting to match reaction shots precisely to the triggering action.

**Story-Aligned Frame Sequencing:** Ordering frames to serve narrative beats rather than chronological order.

---

## AI GENERATIVE VIDEO TERMINOLOGY

### Synthesis/Generation

**Deterministic Clip Synthesis:** Fully reproducible AI video generation with fixed seeds/parameters.

**Frame-Sequence Reconstruction:** Rebuilding a coherent video from incomplete or disordered frames.

**Multi-Segment Video Synthesis:** Generating separate segments then combining them.

**Sequence-to-Sequence Video Synthesis:** End-to-end generation from prompt or initial frame to full clip.

**Conditioned Frame Interpolation:** Interpolation guided by additional control signals (text, depth, motion vectors).

### Latent Space

**Latent Space Interpolation:** Smooth transition between two points in the model's latent space to morph content.

**Latent Motion Scaffolding:** Structuring latent trajectories to guide consistent motion.

**Diffusion Frame Bridging:** Using diffusion steps to connect distant frames coherently.

**Noise-Schedule Alignment:** Matching denoising schedules across clips for seamless stitching.

**Denoising Trajectory Locking:** Fixing the denoising path to preserve identity/motion.

### Coherence/Continuity

**Motion Continuity Fields:** Vector fields that enforce smooth object trajectories.

**Causal Frame Binding:** Ensuring each frame logically follows from the previous.

**Multi-Pass Temporal Refinement:** Iteratively refining the sequence for better consistency.

**Temporal Coherence Pass:** Dedicated processing step focused solely on time-domain consistency.

---

## VOLUMETRIC / VOXEL MANIPULATION

### Grid/Structure

**Voxel Grid Deformation:** Warping a 3D voxel grid to change shape.

**Sparse Voxel Octree Traversal:** Efficient navigation through hierarchical voxel structures.

**Occupancy Grid Encoding:** Representing which voxels contain geometry.

**Point Cloud to Voxel Projection:** Converting points into voxel occupancy.

**Trilinear Interpolation:** Smooth sampling within a voxel grid.

### Rendering

**Volumetric Rendering:** Rendering 3D density fields (smoke, clouds, NeRF).

**Volumetric Ray Marching:** Stepping through volume to accumulate color/density.

**Volumetric Light Transport:** Simulating light scattering inside volumes.

**Neural Radiance Field (NeRF) Sampling:** Querying a trained NeRF for view synthesis.

**Gaussian Splatting:** Fast rendering using 3D Gaussians instead of voxels.

### Sculpting/Manipulation

**Signed Distance Field (SDF) Sculpting:** Carving/modelling using distance-to-surface values.

**Voxel Displacement Mapping:** Pushing/pulling voxel surfaces with textures.

**Density Field Manipulation:** Directly editing volume density values.

**Voxel-Based Fluid Simulation:** Simulating fluids inside voxel grids.

**Marching Cubes Extraction:** Converting voxel data to polygon mesh.

**3D Convolution Kernels:** Applying filters across volumetric data.

### Creative Terms

**Sculptable Space:** Treatable volumetric environment that responds like clay.

**Deformable Matter:** Material that can be pushed, stretched, or molded in 3D.

**Malleable Volumetric Behavior:** Volume that reacts naturally to forces/tools.

---

## VOLUMETRIC RENDERING TECHNIQUES (Expanded)

**Volumetric Rendering**
Core technique for rendering participating media (smoke, clouds, fog, fire, liquids) by simulating how light interacts with density fields throughout a 3D volume rather than just surfaces. Unlike surface-based rendering, it accumulates color and opacity along rays traversing the volume. In AI video pipelines, volumetric rendering is essential for generating realistic atmospheric effects and soft translucency in generative clips (e.g., Runway Gen-3 atmospheric scenes).

**Volumetric Ray Marching**
The primary algorithm for volumetric rendering: cast a ray from the camera through the volume, step along the ray at fixed or adaptive intervals, sample density/opacity/color at each step, then composite contributions using alpha blending or Beer-Lambert absorption. Key parameters: step size (smaller = higher quality, slower), early termination when opacity reaches ~1.0. In 2026 generative tools, ray marching is accelerated with empty-space skipping (via octrees or bounding volumes) to enable real-time preview in Runway ML and similar.

**Volumetric Light Transport**
Simulation of light scattering, absorption, and emission inside participating media. Includes single scattering (direct light → viewer), multiple scattering (light bounces multiple times inside volume), and phase functions (e.g., Henyey-Greenstein for anisotropic scattering in clouds). High-fidelity versions use Monte Carlo path tracing. In AI video, this creates god rays, soft glows, and realistic fog—often baked into neural renderers (NeRF/3DGS) via learned emission-absorption fields.

**Neural Radiance Field (NeRF) Sampling**
NeRF represents a scene as a continuous volumetric function (MLP) mapping 5D coordinates (x,y,z,θ,φ) → (r,g,b, density). Rendering uses volumetric ray marching with quadrature integration along each ray, querying the network hundreds of times per ray. Hierarchical volume sampling (coarse + fine networks) accelerates it. 2026 variants (e.g., Instant-NGP, Zip-NeRF) add hash grids or tensor factorization for 100–1000× speedups, enabling dynamic scene training and real-time rendering in video pipelines.

**Gaussian Splatting (3DGS)**
Modern alternative to NeRF (2023–2026 dominant): represents scenes as millions of anisotropic 3D Gaussians (position, covariance, color, opacity, spherical harmonics). Rendering is differentiable rasterization—no ray marching required—sort tiles, alpha-blend Gaussians front-to-back. Advantages: faster training (minutes vs. hours), real-time rendering (>100 FPS), editable primitives. In Runway ML and similar 2026 tools, 3DGS is preferred for dynamic video because Gaussians can be animated via deformation fields or rigging.

### Practical Pipeline Notes (2026)

- Use Gaussian Splatting for any dynamic or editable scene (superior temporal stability when paired with deformation grids).
- Fall back to optimized NeRF (e.g., Mip-NeRF 360 or Zip-NeRF) when extreme view extrapolation is needed.
- Combine with volumetric ray marching post-process for additional smoke/fog effects that aren't baked into the primal representation.

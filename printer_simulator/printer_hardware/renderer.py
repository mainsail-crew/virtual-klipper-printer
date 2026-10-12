import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

from .axis import Axis


class PrinterRenderer:
    def __init__(
        self,
        width: int,
        height: int,
        image_output_path: str,
        x_axis: Axis,
        y_axis: Axis,
        z_axis: Axis,
    ) -> None:
        self.width = width
        self.height = height
        self.image_output_path = image_output_path
        self.x_axis = x_axis
        self.y_axis = y_axis
        self.z_axis = z_axis

    def render(self):
        """
        Renders a simple 3D visualization of the printer and nozzle position
        using matplotlib for 3D rendering.
        """

        fig = plt.figure(figsize=(self.width / 100, self.height / 100))
        ax = fig.add_subplot(111, projection="3d")
        # Draw printer frame as a wireframe cube
        frame_min = [self.x_axis.min_pos, self.y_axis.min_pos, self.z_axis.min_pos]
        frame_max = [self.x_axis.max_pos, self.y_axis.max_pos, self.z_axis.max_pos]
        r = [frame_min[0], frame_max[0]]
        s = [frame_min[1], frame_max[1]]
        t = [frame_min[2], frame_max[2]]
        # Draw cube edges
        for x in r:
            for y in s:
                ax.plot([x, x], [y, y], t, color="gray", linewidth=1)
        for x in r:
            for z in t:
                ax.plot([x, x], s, [z, z], color="gray", linewidth=1)
        for y in s:
            for z in t:
                ax.plot(r, [y, y], [z, z], color="gray", linewidth=1)
        # Draw nozzle as a red sphere at current position
        nozzle_x = self.x_axis.position
        nozzle_y = self.y_axis.position
        nozzle_z = self.z_axis.position
        u, v = np.mgrid[0 : 2 * np.pi : 20j, 0 : np.pi : 10j]  # type: ignore[misc]
        radius = (
            min(
                (
                    frame_max[0] - frame_min[0],
                    frame_max[1] - frame_min[1],
                    frame_max[2] - frame_min[2],
                )
            )
            * 0.03
        )
        xs = nozzle_x + radius * np.cos(u) * np.sin(v)
        ys = nozzle_y + radius * np.sin(u) * np.sin(v)
        zs = nozzle_z + radius * np.cos(v)
        ax.plot_surface(xs, ys, zs, color="red")
        ax.set_xlabel("X")
        ax.set_ylabel("Y")
        ax.set_zlabel("Z")
        ax.set_xlim(frame_min[0], frame_max[0])
        ax.set_ylim(frame_min[1], frame_max[1])
        ax.set_zlim(frame_min[2], frame_max[2])
        plt.tight_layout()
        plt.savefig(self.image_output_path)
        plt.close(fig)

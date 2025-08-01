//
//  SidebarResizeView.swift
//  Pulse
//
//  Created by Maciek Bagiński on 30/07/2025.
//

import SwiftUI

struct SidebarResizeView: View {
    @EnvironmentObject var browserManager: BrowserManager
    @State private var isResizing = false
    @State private var isHovering = false
    @State private var startingWidth: CGFloat = 0
    @State private var startingMouseX: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 8)
            .contentShape(Rectangle())
            .onHover { hovering in
                guard browserManager.isSidebarVisible else { return }
                
                isHovering = hovering
                
                if hovering && !isResizing {
                    NSCursor.resizeLeftRight.set()
                } else if !hovering && !isResizing {
                    NSCursor.arrow.set()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        guard browserManager.isSidebarVisible else { return }
                        
                        if !isResizing {
                            startingWidth = browserManager.sidebarWidth
                            startingMouseX = value.startLocation.x
                            isResizing = true
                            NSCursor.resizeLeftRight.set()
                        }
                        
                        // Use absolute mouse positions for true 1:1 tracking
                        let currentMouseX = value.location.x
                        let mouseMovement = currentMouseX - startingMouseX
                        let newWidth = startingWidth + mouseMovement
                        let clampedWidth = max(100, min(400, newWidth))
                        
                        browserManager.updateSidebarWidth(clampedWidth)
                    }
                    .onEnded { _ in
                        isResizing = false
                        browserManager.saveSidebarWidthToDefaults()
                        
                        if isHovering {
                            NSCursor.resizeLeftRight.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
            )
    }
}

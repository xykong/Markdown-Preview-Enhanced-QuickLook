describe('Anchor Matching with Three-Level Tolerant Strategy', () => {
    function compressMultipleHyphens(text: string): string {
        return text.replace(/-+/g, '-');
    }

    function unifyUnderscoreAndHyphen(text: string): string {
        return text.replace(/[_-]/g, '~');
    }

    function findElementByAnchorMock(anchorId: string, availableIds: string[]): string | null {
        if (availableIds.includes(anchorId)) {
            return anchorId;
        }
        
        const level2NormalizedTarget = compressMultipleHyphens(anchorId);
        for (const id of availableIds) {
            if (compressMultipleHyphens(id) === level2NormalizedTarget) {
                return id;
            }
        }
        
        const level3NormalizedTarget = unifyUnderscoreAndHyphen(compressMultipleHyphens(anchorId));
        for (const id of availableIds) {
            if (unifyUnderscoreAndHyphen(compressMultipleHyphens(id)) === level3NormalizedTarget) {
                return id;
            }
        }
        
        return null;
    }

    it('should match exact anchor IDs', () => {
        const availableIds = ['section-one', 'section-two', 'facility-类型概览'];
        
        expect(findElementByAnchorMock('section-one', availableIds)).toBe('section-one');
        expect(findElementByAnchorMock('facility-类型概览', availableIds)).toBe('facility-类型概览');
    });

    it('should match anchors with multiple consecutive hyphens', () => {
        const availableIds = [
            'app_metrics-应用性能监控',
            'backend_callback-后端回调追踪',
            'section-two'
        ];
        
        expect(findElementByAnchorMock('app_metrics---应用性能监控', availableIds)).toBe('app_metrics-应用性能监控');
        expect(findElementByAnchorMock('backend_callback---后端回调追踪', availableIds)).toBe('backend_callback-后端回调追踪');
        expect(findElementByAnchorMock('section---two', availableIds)).toBe('section-two');
    });

    it('should handle Chinese characters correctly', () => {
        const availableIds = ['中文标题测试', '高离散度字段说明'];
        
        expect(findElementByAnchorMock('中文标题测试', availableIds)).toBe('中文标题测试');
        expect(findElementByAnchorMock('高离散度字段说明', availableIds)).toBe('高离散度字段说明');
    });

    it('should handle mixed Latin and Chinese with hyphens', () => {
        const availableIds = [
            'app_metrics-应用性能监控',
            'backend-prod-后端生产日志',
            'plog-性能监控'
        ];
        
        expect(findElementByAnchorMock('app_metrics---应用性能监控', availableIds)).toBe('app_metrics-应用性能监控');
        expect(findElementByAnchorMock('backend-prod---后端生产日志', availableIds)).toBe('backend-prod-后端生产日志');
        expect(findElementByAnchorMock('plog---性能监控', availableIds)).toBe('plog-性能监控');
    });

    it('should return null for non-existent anchors', () => {
        const availableIds = ['section-one', 'section-two'];
        
        expect(findElementByAnchorMock('non-existent', availableIds)).toBeNull();
        expect(findElementByAnchorMock('section-three', availableIds)).toBeNull();
    });

    it('should prefer exact matches over normalized matches', () => {
        const availableIds = ['section--two', 'section-two'];
        
        expect(findElementByAnchorMock('section--two', availableIds)).toBe('section--two');
    });

    it('should match underscore and hyphen as equivalent (level 3)', () => {
        const availableIds = [
            'backend-callback-后端回调追踪',
            'anipop_exporter-日志采集服务'
        ];
        
        expect(findElementByAnchorMock('backend_callback---后端回调追踪', availableIds)).toBe('backend-callback-后端回调追踪');
        expect(findElementByAnchorMock('anipop-exporter---日志采集服务', availableIds)).toBe('anipop_exporter-日志采集服务');
    });

    it('should prioritize exact match over level 2 and level 3 normalization', () => {
        const availableIds = [
            'backend_callback-后端回调追踪',
            'backend-callback-后端回调追踪'
        ];
        
        expect(findElementByAnchorMock('backend_callback---后端回调追踪', availableIds)).toBe('backend_callback-后端回调追踪');
    });

    it('should prioritize level 2 (hyphen compression) over level 3 (underscore unification)', () => {
        const availableIds = [
            'section---two',
            'section_two'
        ];
        
        expect(findElementByAnchorMock('section---two', availableIds)).toBe('section---two');
    });

    it('should handle real-world TOC link cases from graylog_business_fields.md', () => {
        const availableIds = [
            'facility-类型概览',
            'app_metrics-应用性能监控',
            'backend_callback-后端回调追踪',
            'backend_prod-后端生产日志',
            'anipop_exporter-日志采集服务',
            'animal_locks_k8s-锁任务调度',
            'plog-性能监控',
            'web_console-web-控制台',
            '高离散度字段说明'
        ];
        
        expect(findElementByAnchorMock('facility-类型概览', availableIds)).toBe('facility-类型概览');
        expect(findElementByAnchorMock('app_metrics---应用性能监控', availableIds)).toBe('app_metrics-应用性能监控');
        expect(findElementByAnchorMock('backend_callback---后端回调追踪', availableIds)).toBe('backend_callback-后端回调追踪');
        expect(findElementByAnchorMock('backend_prod---后端生产日志', availableIds)).toBe('backend_prod-后端生产日志');
        expect(findElementByAnchorMock('anipop_exporter---日志采集服务', availableIds)).toBe('anipop_exporter-日志采集服务');
        expect(findElementByAnchorMock('animal_locks_k8s---锁任务调度', availableIds)).toBe('animal_locks_k8s-锁任务调度');
        expect(findElementByAnchorMock('plog---性能监控', availableIds)).toBe('plog-性能监控');
        expect(findElementByAnchorMock('web_console---web-控制台', availableIds)).toBe('web_console-web-控制台');
        expect(findElementByAnchorMock('高离散度字段说明', availableIds)).toBe('高离散度字段说明');
    });
});

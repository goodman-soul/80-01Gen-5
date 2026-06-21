<script lang="ts">
	import type { PageData } from './$types';
	import type { CheckIn, Review, Video } from '$lib/types';
	import { MoodLabels } from '$lib/types';
	import { Calendar, MessageCircle, Video as VideoIcon, Star, ClipboardList } from 'lucide-svelte';
	import { onMount } from 'svelte';

	export let data: PageData;

	let checkIns: (CheckIn & {
		homework?: { title: string; exercise_type: string };
		child?: { name: string };
		review?: Review;
		videos?: Video[];
	})[] = [];
	let loading = true;

	onMount(async () => {
		if (!data.children || data.children.length === 0) {
			loading = false;
			return;
		}

		const childIds = data.children.map((c) => c.id);
		const { data: ciData } = await data.supabase
			.from('check_ins')
			.select('*, homework:assigned_homeworks(title, exercise_type), child:children(name), review:reviews(*), videos(*)')
			.in('child_id', childIds)
			.order('created_at', { ascending: false });

		checkIns = ciData || [];
		loading = false;
	});

	function getMoodEmoji(mood: string | null) {
		switch (mood) {
			case 'happy':
				return '😊';
			case 'good':
				return '🙂';
			case 'neutral':
				return '😐';
			case 'tired':
				return '😴';
			case 'unwilling':
				return '😟';
			default:
				return '';
		}
	}
</script>

<div class="max-w-6xl mx-auto px-4 py-8">
	<div class="mb-6">
		<h1 class="text-2xl font-bold text-gray-900">打卡记录</h1>
		<p class="text-gray-500 text-sm">查看历史打卡和治疗师反馈</p>
	</div>

	{#if loading}
		<div class="flex justify-center py-12">
			<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500" />
		</div>
	{:else if checkIns.length === 0}
		<div class="card p-12 text-center">
			<ClipboardList class="w-16 h-16 text-gray-300 mx-auto mb-4" />
			<p class="text-gray-500 mb-2">暂无打卡记录</p>
			<p class="text-sm text-gray-400">完成作业后打卡记录会显示在这里</p>
		</div>
	{:else}
		<div class="space-y-4">
			{#each checkIns as ci}
				<div class="card p-6">
					<div class="flex items-start justify-between mb-4">
						<div>
							<div class="flex items-center gap-2 mb-1">
								<h3 class="font-semibold text-gray-900">{ci.homework?.title || '训练打卡'}</h3>
								{#if ci.child}
									<span class="text-sm text-gray-500">· {ci.child.name}</span>
								{/if}
							</div>
							<p class="text-sm text-gray-500 flex items-center">
								<Calendar class="w-4 h-4 mr-1" />
								{ci.check_in_date}
								{#if ci.mood}
									<span class="ml-2">{getMoodEmoji(ci.mood)} {MoodLabels[ci.mood]}</span>
								{/if}
							</p>
						</div>
						{#if ci.review}
							<span class="badge bg-purple-100 text-purple-700">已评审</span>
						{/if}
					</div>

					{#if ci.notes}
						<div class="bg-gray-50 rounded-lg p-3 mb-4">
							<p class="text-sm text-gray-700">{ci.notes}</p>
						</div>
					{/if}

					{#if ci.videos && ci.videos.length > 0}
						<div class="mb-4">
							<p class="text-sm text-gray-600 mb-2 flex items-center">
								<VideoIcon class="w-4 h-4 mr-1" />
								视频 ({ci.videos.length})
							</p>
							<div class="flex gap-2 overflow-x-auto pb-2">
								{#each ci.videos as video}
									<div class="w-32 h-20 bg-gray-200 rounded-lg flex items-center justify-center flex-shrink-0">
										<VideoIcon class="w-8 h-8 text-gray-400" />
									</div>
								{/each}
							</div>
						</div>
					{/if}

					{#if ci.review}
						<div class="bg-purple-50 border border-purple-100 rounded-xl p-4">
							<div class="flex items-center gap-2 mb-3">
								<MessageCircle class="w-5 h-5 text-purple-600" />
								<span class="font-medium text-purple-900">治疗师反馈</span>
								{#if ci.review.overall_rating}
									<div class="flex items-center ml-2">
										{#each { length: 5 } as _, i}
											<Star
												class={`w-4 h-4 ${
													i < (ci.review?.overall_rating || 0)
														? 'text-yellow-400 fill-yellow-400'
														: 'text-gray-300'
												}`}
											/>
										{/each}
									</div>
								{/if}
							</div>
							{#if ci.review.feedback}
								<p class="text-sm text-gray-700 mb-2">{ci.review.feedback}</p>
							{/if}
							{#if ci.review.next_adjustment}
								<div class="mt-2 p-3 bg-white rounded-lg">
									<p class="text-xs text-gray-500 mb-1">下次训练调整：</p>
									<p class="text-sm text-gray-800">{ci.review.next_adjustment}</p>
								</div>
							{/if}
						</div>
					{/if}
				</div>
			{/each}
		</div>
	{/if}
</div>
